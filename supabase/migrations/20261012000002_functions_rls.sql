-- Allô Vino — Lot 1 : fonctions, déclencheurs et RLS (README sections 5.2, 5.3, 5.5)
-- Écarts volontaires par rapport au README, pour fermer des failles :
--   * les colonnes sensibles (rôle, statuts, Stripe, montants) ne sont modifiables que côté serveur ;
--   * le créateur d'un domaine en devient propriétaire automatiquement ;
--   * un média (audio ou vidéo) ne peut être créé qu'au statut « uploaded », seul n8n le fait avancer.

-- 1. Appartenance -------------------------------------------------------------

create or replace function public.is_member(d uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.domaine_members m where m.domaine_id = d and m.user_id = auth.uid());
$$;

create or replace function public.is_odg_member(a uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.appellation_members m where m.appellation_id = a and m.user_id = auth.uid());
$$;

-- Vrai quand la requête vient d'un client (clé anon ou jeton utilisateur), faux pour
-- la clé service, l'éditeur SQL et les fonctions security definer.
create or replace function public.is_client_request()
returns boolean language sql stable as $$
  select current_user in ('anon', 'authenticated');
$$;

-- 2. Déclencheurs ------------------------------------------------------------

-- Profil créé à l'inscription
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Le rôle ne se change pas depuis le client
create or replace function public.protect_profile()
returns trigger language plpgsql as $$
begin
  if public.is_client_request() and new.role is distinct from old.role then
    raise exception 'Le rôle ne peut pas être modifié depuis l''app';
  end if;
  return new;
end $$;

create trigger protect_profile before update on public.profiles
  for each row execute function public.protect_profile();

-- Domaine : créateur propriétaire, statut et Stripe réservés au serveur
create or replace function public.handle_new_domaine()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null then
    insert into public.domaine_members (domaine_id, user_id, role) values (new.id, auth.uid(), 'owner')
      on conflict do nothing;
    update public.profiles set role = 'vigneron' where id = auth.uid() and role = 'consumer';
  end if;
  return new;
end $$;

create trigger on_domaine_created after insert on public.domaines
  for each row execute function public.handle_new_domaine();

create or replace function public.protect_domaine()
returns trigger language plpgsql as $$
begin
  if public.is_client_request() and (
    new.status is distinct from old.status
    or new.stripe_account_id is distinct from old.stripe_account_id
    or new.slug is distinct from old.slug
  ) then
    raise exception 'Statut, compte Stripe et adresse du domaine sont gérés par Allô Vino';
  end if;
  return new;
end $$;

create trigger protect_domaine before update on public.domaines
  for each row execute function public.protect_domaine();

-- Appellation : statut et adresse réservés au serveur
create or replace function public.protect_appellation()
returns trigger language plpgsql as $$
begin
  if public.is_client_request() and (
    new.status is distinct from old.status or new.slug is distinct from old.slug
  ) then
    raise exception 'Statut et adresse de l''appellation sont gérés par Allô Vino';
  end if;
  return new;
end $$;

create trigger protect_appellation before update on public.appellations
  for each row execute function public.protect_appellation();

-- Commande : côté client, seul le passage « payée → expédiée » est permis
create or replace function public.protect_order()
returns trigger language plpgsql as $$
begin
  if public.is_client_request() and (
    (to_jsonb(new) - 'status') is distinct from (to_jsonb(old) - 'status')
    or not (old.status = 'paid' and new.status = 'shipped')
  ) then
    raise exception 'Seul le passage d''une commande payée à expédiée est possible';
  end if;
  return new;
end $$;

create trigger protect_order before update on public.orders
  for each row execute function public.protect_order();

-- 3. RLS ---------------------------------------------------------------------

alter table public.profiles             enable row level security;
alter table public.domaines             enable row level security;
alter table public.domaine_members      enable row level security;
alter table public.appellations         enable row level security;
alter table public.appellation_members  enable row level security;
alter table public.appellation_domaines enable row level security;
alter table public.wines                enable row level security;
alter table public.medias               enable row level security;
alter table public.saves                enable row level security;
alter table public.follows              enable row level security;
alter table public.likes                enable row level security;
alter table public.events               enable row level security;
alter table public.orders               enable row level security;
alter table public.order_items          enable row level security;

-- Profils : lecture et mise à jour de son propre profil (création par déclencheur)
create policy "profil_read"   on public.profiles for select using (id = auth.uid());
create policy "profil_update" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

-- Domaines : actifs publics ; membres ; ODG pour les domaines liés à son appellation
create policy "domaines_read" on public.domaines for select using (
  status = 'active'
  or public.is_member(id)
  or exists (select 1 from public.appellation_domaines ad
             where ad.domaine_id = domaines.id and public.is_odg_member(ad.appellation_id))
);
create policy "domaines_create" on public.domaines for insert
  with check (auth.uid() is not null and status = 'pending' and stripe_account_id is null);
create policy "domaines_write" on public.domaines for update
  using (public.is_member(id)) with check (public.is_member(id));

create policy "members_read" on public.domaine_members for select
  using (user_id = auth.uid() or public.is_member(domaine_id));

-- Appellations : actives publiques, mise à jour par l'ODG, création par l'admin (serveur)
create policy "appellations_read"  on public.appellations for select using (status = 'active' or public.is_odg_member(id));
create policy "appellations_write" on public.appellations for update
  using (public.is_odg_member(id)) with check (public.is_odg_member(id));

create policy "odg_members_read" on public.appellation_members for select
  using (user_id = auth.uid() or public.is_odg_member(appellation_id));

-- Adhésions : le domaine demande ou quitte, l'ODG invite et valide
create policy "adhesions_read" on public.appellation_domaines for select using (
  status = 'active' or public.is_member(domaine_id) or public.is_odg_member(appellation_id)
);
create policy "adhesions_request" on public.appellation_domaines for insert with check (
  (public.is_member(domaine_id) and status = 'pending' and not invited_by_odg)
  or public.is_odg_member(appellation_id)
);
create policy "adhesions_odg" on public.appellation_domaines for update
  using (public.is_odg_member(appellation_id)) with check (public.is_odg_member(appellation_id));
create policy "adhesions_leave" on public.appellation_domaines for update
  using (public.is_member(domaine_id)) with check (public.is_member(domaine_id) and status = 'left');

-- Cuvées : publiées publiques, gestion par les membres ;
-- une cuvée ne se rattache qu'à une appellation dont le domaine est adhérent actif
create policy "wines_read" on public.wines for select using (is_published or public.is_member(domaine_id));
create policy "wines_write" on public.wines for all
  using (public.is_member(domaine_id))
  with check (
    public.is_member(domaine_id)
    and (appellation_id is null or exists (
      select 1 from public.appellation_domaines ad
      where ad.appellation_id = wines.appellation_id and ad.domaine_id = wines.domaine_id and ad.status = 'active'))
  );

-- Médias (audio ou vidéo) : publiés publics ; le domaine ou l'ODG dépose (statut « uploaded »)
-- et supprime. Aucune mise à jour côté client : conversion, transcription et publication passent par n8n.
create policy "medias_read" on public.medias for select using (
  status = 'published'
  or (domaine_id is not null and public.is_member(domaine_id))
  or (appellation_id is not null and public.is_odg_member(appellation_id))
);
create policy "medias_insert" on public.medias for insert with check (
  status = 'uploaded' and ai_draft is null and transcript is null and compliance_flags = '{}'
  and published_path is null and poster_path is null
  and (
    (domaine_id is not null and public.is_member(domaine_id)
      and exists (select 1 from public.wines w where w.id = medias.wine_id and w.domaine_id = medias.domaine_id))
    or (appellation_id is not null and public.is_odg_member(appellation_id))
  )
);
create policy "medias_delete" on public.medias for delete using (
  (domaine_id is not null and public.is_member(domaine_id))
  or (appellation_id is not null and public.is_odg_member(appellation_id))
);

-- Social
create policy "saves_self"   on public.saves   for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "follows_self" on public.follows for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "likes_read"   on public.likes   for select using (true);
create policy "likes_self"   on public.likes   for insert with check (user_id = auth.uid());
create policy "likes_del"    on public.likes   for delete using (user_id = auth.uid());

-- Statistiques : insertion anonyme, lecture brute par le domaine concerné uniquement
create policy "events_insert" on public.events for insert with check (true);
create policy "events_read"   on public.events for select using (
  exists (select 1 from public.wines w where w.id = wine_id and public.is_member(w.domaine_id))
);

-- Commandes : le client et le domaine ; jamais l'ODG. Création par n8n (clé service).
create policy "orders_read" on public.orders for select using (user_id = auth.uid() or public.is_member(domaine_id));
create policy "orders_ship" on public.orders for update
  using (public.is_member(domaine_id)) with check (public.is_member(domaine_id));
create policy "items_read" on public.order_items for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.user_id = auth.uid() or public.is_member(o.domaine_id)))
);

-- 4. Statistiques agrégées pour l'ODG (sans ventes) --------------------------

create or replace function public.appellation_stats(a uuid, since timestamptz)
returns table (domaine_id uuid, scans bigint, plays bigint, completes bigint, saves bigint)
language sql stable security definer set search_path = public as $$
  select w.domaine_id,
         count(*) filter (where e.type = 'scan'),
         count(*) filter (where e.type = 'play'),
         count(*) filter (where e.type = 'complete'),
         count(*) filter (where e.type = 'save')
  from public.events e
  join public.wines w on w.id = e.wine_id
  where w.appellation_id = a
    and e.created_at >= since
    and public.is_odg_member(a)
  group by w.domaine_id;
$$;

revoke execute on function public.appellation_stats(uuid, timestamptz) from public, anon;
grant execute on function public.appellation_stats(uuid, timestamptz) to authenticated;
