-- Allô Vino — tests RLS du lot 1
-- À coller dans l'éditeur SQL de Supabase APRÈS les migrations et le seed.
-- Crée des données de test, joue chaque scénario avec le bon rôle, nettoie tout,
-- puis affiche un tableau : une ligne par test, colonne « ok » à true attendue partout.

create temp table if not exists rls_results (n serial, test text, ok boolean, detail text);
truncate rls_results;

do $$
declare
  u_vig   uuid := 'e0000000-0000-4000-a000-000000000001'; -- vigneron du domaine test
  u_cli   uuid := 'e0000000-0000-4000-a000-000000000002'; -- consommateur
  u_odg   uuid := 'e0000000-0000-4000-a000-000000000003'; -- membre de l'ODG test
  d_test  uuid := 'f0000000-0000-4000-a000-000000000001';
  a_test  uuid := 'f0000000-0000-4000-a000-000000000002';
  w_pub   uuid := 'f0000000-0000-4000-a000-000000000003';
  w_draft uuid := 'f0000000-0000-4000-a000-000000000004';
  o_test  uuid := 'f0000000-0000-4000-a000-000000000005';
  n int;
  t text;
begin
  -- Données de test (en tant que postgres) -----------------------------------
  insert into auth.users (id, email) values
    (u_vig, 'vigneron@test.allovino.local'),
    (u_cli, 'client@test.allovino.local'),
    (u_odg, 'odg@test.allovino.local');
  insert into public.appellations (id, slug, name, kind, region, status)
    values (a_test, 'test-appellation', 'Test AOP', 'aop', 'Test', 'active');
  insert into public.domaines (id, slug, name, first_name, region, status)
    values (d_test, 'test-domaine', 'Domaine Test', 'Test', 'Test', 'active');
  insert into public.domaine_members (domaine_id, user_id) values (d_test, u_vig);
  insert into public.appellation_members (appellation_id, user_id) values (a_test, u_odg);
  insert into public.appellation_domaines (appellation_id, domaine_id, status) values (a_test, d_test, 'active');
  insert into public.wines (id, domaine_id, appellation_id, slug, name, color, is_published) values
    (w_pub,   d_test, a_test, 'test-cuvee-publiee',   'Publiée',   'rouge', true),
    (w_draft, d_test, a_test, 'test-cuvee-brouillon', 'Brouillon', 'blanc', false);
  insert into public.events (wine_id, type, source) values (w_pub, 'scan', 'qr');
  insert into public.orders (id, user_id, domaine_id, status, subtotal_cents, shipping_cents, total_cents, age_confirmed_at)
    values (o_test, u_cli, d_test, 'paid', 1250, 590, 1840, now());

  -- T01 -------------------------------------------------------------------------
  t := 'Visiteur sans compte : ne voit pas une cuvée non publiée';
  begin
    set local role anon;
    perform set_config('request.jwt.claims', '{"role":"anon"}', true);
    select count(*) into n from public.wines where id = w_draft;
    reset role;
    insert into rls_results (test, ok) values (t, n = 0);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Visiteur sans compte : voit une cuvée publiée';
  begin
    set local role anon;
    perform set_config('request.jwt.claims', '{"role":"anon"}', true);
    select count(*) into n from public.wines where id = w_pub;
    reset role;
    insert into rls_results (test, ok) values (t, n = 1);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Utilisateur non membre : ne voit pas une cuvée non publiée';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_cli, 'role', 'authenticated')::text, true);
    select count(*) into n from public.wines where id = w_draft;
    reset role;
    insert into rls_results (test, ok) values (t, n = 0);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Vigneron : voit sa propre cuvée non publiée';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_vig, 'role', 'authenticated')::text, true);
    select count(*) into n from public.wines where id = w_draft;
    reset role;
    insert into rls_results (test, ok) values (t, n = 1);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Utilisateur non membre : ne peut pas modifier un domaine';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_cli, 'role', 'authenticated')::text, true);
    update public.domaines set name = 'Piraté' where id = d_test;
    get diagnostics n = row_count;
    reset role;
    insert into rls_results (test, ok) values (t, n = 0);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Vigneron : peut modifier la fiche de son domaine';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_vig, 'role', 'authenticated')::text, true);
    update public.domaines set bio = 'Nouvelle bio' where id = d_test;
    get diagnostics n = row_count;
    reset role;
    insert into rls_results (test, ok) values (t, n = 1);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Vigneron : ne peut pas changer le statut de son domaine';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_vig, 'role', 'authenticated')::text, true);
    update public.domaines set status = 'suspended' where id = d_test;
    reset role;
    insert into rls_results (test, ok, detail) values (t, false, 'la modification a été acceptée');
  exception when others then insert into rls_results (test, ok, detail) values (t, true, sqlerrm); end;

  t := 'Utilisateur : ne peut pas se donner le rôle admin';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_cli, 'role', 'authenticated')::text, true);
    update public.profiles set role = 'admin' where id = u_cli;
    reset role;
    insert into rls_results (test, ok, detail) values (t, false, 'la modification a été acceptée');
  exception when others then insert into rls_results (test, ok, detail) values (t, true, sqlerrm); end;

  t := 'Utilisateur : ne peut pas créer un domaine déjà actif';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_cli, 'role', 'authenticated')::text, true);
    insert into public.domaines (slug, name, first_name, region, status)
      values ('test-domaine-actif', 'Actif', 'X', 'Test', 'active');
    reset role;
    insert into rls_results (test, ok, detail) values (t, false, 'la création a été acceptée');
  exception when others then insert into rls_results (test, ok, detail) values (t, true, sqlerrm); end;

  t := 'Utilisateur : crée un domaine en attente et en devient propriétaire';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_cli, 'role', 'authenticated')::text, true);
    insert into public.domaines (slug, name, first_name, region)
      values ('test-domaine-nouveau', 'Nouveau', 'X', 'Test');
    reset role;
    select count(*) into n from public.domaine_members m join public.domaines d on d.id = m.domaine_id
      where d.slug = 'test-domaine-nouveau' and m.user_id = u_cli and m.role = 'owner';
    insert into rls_results (test, ok) values (t, n = 1);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Vigneron : ne peut pas créer un média déjà publié';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_vig, 'role', 'authenticated')::text, true);
    insert into public.medias (wine_id, domaine_id, kind, storage_path, status)
      values (w_pub, d_test, 'audio', 'x.webm', 'published');
    reset role;
    insert into rls_results (test, ok, detail) values (t, false, 'la création a été acceptée');
  exception when others then insert into rls_results (test, ok, detail) values (t, true, sqlerrm); end;

  t := 'Vigneron : peut déposer une vidéo sur sa cuvée';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_vig, 'role', 'authenticated')::text, true);
    insert into public.medias (wine_id, domaine_id, kind, storage_path)
      values (w_pub, d_test, 'video', d_test || '/' || w_pub || '/test.mp4');
    reset role;
    insert into rls_results (test, ok) values (t, true);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Vigneron : ne peut pas modifier le montant d''une commande';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_vig, 'role', 'authenticated')::text, true);
    update public.orders set total_cents = 1 where id = o_test;
    reset role;
    insert into rls_results (test, ok, detail) values (t, false, 'la modification a été acceptée');
  exception when others then insert into rls_results (test, ok, detail) values (t, true, sqlerrm); end;

  t := 'Client : voit sa commande';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_cli, 'role', 'authenticated')::text, true);
    select count(*) into n from public.orders where id = o_test;
    reset role;
    insert into rls_results (test, ok) values (t, n = 1);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'ODG : ne voit pas les commandes des domaines';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_odg, 'role', 'authenticated')::text, true);
    select count(*) into n from public.orders where id = o_test;
    reset role;
    insert into rls_results (test, ok) values (t, n = 0);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'ODG : ne voit pas les statistiques brutes';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_odg, 'role', 'authenticated')::text, true);
    select count(*) into n from public.events where wine_id = w_pub;
    reset role;
    insert into rls_results (test, ok) values (t, n = 0);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'ODG : voit les statistiques agrégées de son appellation';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_odg, 'role', 'authenticated')::text, true);
    select coalesce(sum(scans), 0) into n from public.appellation_stats(a_test, now() - interval '1 day');
    reset role;
    insert into rls_results (test, ok) values (t, n = 1);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'Utilisateur hors ODG : statistiques agrégées vides';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_cli, 'role', 'authenticated')::text, true);
    select count(*) into n from public.appellation_stats(a_test, now() - interval '1 day');
    reset role;
    insert into rls_results (test, ok) values (t, n = 0);
  exception when others then insert into rls_results (test, ok, detail) values (t, false, sqlerrm); end;

  t := 'ODG : ne peut pas activer lui-même son appellation';
  begin
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', u_odg, 'role', 'authenticated')::text, true);
    update public.appellations set status = 'suspended' where id = a_test;
    reset role;
    insert into rls_results (test, ok, detail) values (t, false, 'la modification a été acceptée');
  exception when others then insert into rls_results (test, ok, detail) values (t, true, sqlerrm); end;

  -- Nettoyage (en tant que postgres) ----------------------------------------
  reset role;
  delete from public.orders where id = o_test;
  delete from public.domaines where slug like 'test-%';
  delete from public.appellations where slug like 'test-%';
  delete from auth.users where email like '%@test.allovino.local';
end $$;

select n, test, ok, detail from rls_results order by n;
