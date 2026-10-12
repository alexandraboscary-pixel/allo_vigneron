-- Allô Vino — lot 1 tout-en-un : schéma + RLS + stockage + données de démo
-- À coller en une fois dans Supabase > SQL Editor > New query, puis Run.

-- ===== migrations/20261012000001_schema.sql =====
-- Allô Vino — Lot 1 : schéma (README section 5.1)

create extension if not exists pgcrypto;

-- Profils
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  birthdate date,
  role text not null default 'consumer' check (role in ('consumer','vigneron','odg','admin')),
  created_at timestamptz not null default now()
);

-- Domaines
create table public.domaines (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  first_name text not null,
  region text not null,
  bio text,
  color_1 text not null default '#FF8FAB',
  color_2 text not null default '#FFC79E',
  avatar_path text,
  siret text,
  stripe_account_id text,
  sales_enabled boolean not null default false,
  status text not null default 'pending' check (status in ('pending','active','suspended')),
  created_at timestamptz not null default now()
);

create table public.domaine_members (
  domaine_id uuid references public.domaines(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','editor')),
  primary key (domaine_id, user_id)
);

-- Appellations
create table public.appellations (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  kind text not null check (kind in ('aop','igp')),
  organisme text,
  region text not null,
  bio text,
  mots text[] not null default '{}',
  color_1 text not null default '#FF8FAB',
  color_2 text not null default '#FFC79E',
  logo_path text,
  status text not null default 'pending' check (status in ('pending','active','suspended')),
  created_at timestamptz not null default now()
);

create table public.appellation_members (
  appellation_id uuid references public.appellations(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','editor')),
  primary key (appellation_id, user_id)
);

create table public.appellation_domaines (
  appellation_id uuid references public.appellations(id) on delete cascade,
  domaine_id uuid references public.domaines(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','active','left')),
  invited_by_odg boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (appellation_id, domaine_id)
);

-- Cuvées
create table public.wines (
  id uuid primary key default gen_random_uuid(),
  domaine_id uuid not null references public.domaines(id) on delete cascade,
  appellation_id uuid references public.appellations(id) on delete set null,
  slug text unique not null,
  name text not null,
  color text not null check (color in ('rouge','rose','blanc','bulles','orange')),
  vintage int,
  grapes text,
  abv numeric(3,1),
  price_cents int check (price_cents >= 0),
  stock int not null default 0,
  mots text[] not null default '{}',
  tags text[] not null default '{}' check (tags <@ array['apero','pizza','frais','bulles','petitprix']),
  pairings text,
  label_image_path text,
  label_style jsonb,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

-- Médias : audio ou vidéo, au choix de l'auteur (cuvée ou appellation)
create table public.medias (
  id uuid primary key default gen_random_uuid(),
  wine_id uuid references public.wines(id) on delete cascade,
  domaine_id uuid references public.domaines(id) on delete cascade,
  appellation_id uuid references public.appellations(id) on delete cascade,
  kind text not null check (kind in ('audio','video')),
  storage_path text not null,                 -- fichier brut dans medias-raw
  published_path text,                        -- fichier converti dans medias (n8n)
  poster_path text,                           -- image d'aperçu, vidéo uniquement (n8n)
  duration_s int,
  transcript text,
  segments jsonb,
  ai_draft jsonb,
  compliance_flags text[] not null default '{}',
  status text not null default 'uploaded'
    check (status in ('uploaded','processing','review','published','error')),
  created_at timestamptz not null default now(),
  check (
    (wine_id is not null and domaine_id is not null and appellation_id is null)
    or (wine_id is null and domaine_id is null and appellation_id is not null)
  )
);

-- Social
create table public.saves   (user_id uuid references auth.users(id) on delete cascade, wine_id uuid references public.wines(id) on delete cascade, created_at timestamptz default now(), primary key (user_id, wine_id));
create table public.follows (user_id uuid references auth.users(id) on delete cascade, domaine_id uuid references public.domaines(id) on delete cascade, created_at timestamptz default now(), primary key (user_id, domaine_id));
create table public.likes   (user_id uuid references auth.users(id) on delete cascade, media_id uuid references public.medias(id) on delete cascade, created_at timestamptz default now(), primary key (user_id, media_id));

-- Statistiques (anonymes)
create table public.events (
  id bigserial primary key,
  wine_id uuid references public.wines(id) on delete cascade,
  appellation_id uuid references public.appellations(id) on delete cascade,
  type text not null check (type in ('scan','play','complete','save','buy_click')),
  source text check (source in ('qr','qr_collectif','image','feed','explore','story','appellation')),
  created_at timestamptz not null default now(),
  check (wine_id is not null or appellation_id is not null)
);

-- Commandes
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  domaine_id uuid not null references public.domaines(id),
  status text not null default 'pending' check (status in ('pending','paid','shipped','cancelled','refunded')),
  subtotal_cents int not null,
  shipping_cents int not null,
  total_cents int not null,
  stripe_session_id text unique,
  shipping_address jsonb,
  age_confirmed_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.order_items (
  order_id uuid references public.orders(id) on delete cascade,
  wine_id uuid references public.wines(id),
  qty int not null check (qty > 0),
  unit_price_cents int not null,
  primary key (order_id, wine_id)
);

-- Index
create index on public.wines (domaine_id);
create index on public.wines (appellation_id);
create index on public.appellation_domaines (domaine_id);
create index on public.medias (wine_id, status);
create index on public.medias (appellation_id, status);
create index on public.events (wine_id, type, created_at);
create index on public.events (appellation_id, type, created_at);
create index on public.orders (domaine_id);
create index on public.orders (user_id);

-- ===== migrations/20261012000002_functions_rls.sql =====
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

-- ===== migrations/20261012000003_storage.sql =====
-- Allô Vino — Lot 1 : stockage des fichiers (README section 5.4)
-- Chemins : {domaine_id}/{wine_id}/{fichier} ou appellations/{appellation_id}/{fichier}

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('medias-raw', 'medias-raw', false, 209715200, array['audio/*', 'video/*']),
  ('medias',     'medias',     true,  52428800,  array['audio/*', 'video/*', 'image/*']),
  ('labels',     'labels',     true,  5242880,  array['image/*']),
  ('avatars',    'avatars',    true,  5242880,  array['image/*'])
on conflict (id) do nothing;

-- Le premier dossier du chemin désigne le domaine (ou « appellations » puis l'appellation)
create or replace function public.can_write_object(object_name text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare
  parts text[] := storage.foldername(object_name);
begin
  if parts[1] = 'appellations' then
    return public.is_odg_member(parts[2]::uuid);
  end if;
  return public.is_member(parts[1]::uuid);
exception when invalid_text_representation then
  return false;
end $$;

-- medias-raw : privé, membres seulement (n8n lit avec la clé service)
create policy "raw_read" on storage.objects for select to authenticated
  using (bucket_id = 'medias-raw' and public.can_write_object(name));
create policy "raw_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'medias-raw' and public.can_write_object(name));
create policy "raw_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'medias-raw' and public.can_write_object(name));

-- labels et avatars : lecture publique (bucket public), écriture par les membres
create policy "images_insert" on storage.objects for insert to authenticated
  with check (bucket_id in ('labels', 'avatars') and public.can_write_object(name));
create policy "images_update" on storage.objects for update to authenticated
  using (bucket_id in ('labels', 'avatars') and public.can_write_object(name))
  with check (bucket_id in ('labels', 'avatars') and public.can_write_object(name));
create policy "images_delete" on storage.objects for delete to authenticated
  using (bucket_id in ('labels', 'avatars') and public.can_write_object(name));

-- medias : aucune écriture côté client, n8n y dépose les fichiers convertis et les aperçus

-- ===== seed.sql =====
-- Allô Vino — données de démo (lot 1)
-- Appellation, domaines et cuvées FICTIFS, provisoires : à remplacer par les 5 domaines et
-- 7 cuvées de glou-prototype.html dès que le prototype est dans le dépôt.
-- Pas de média (audio ou vidéo) ni de compte ici : ils arrivent aux lots 2 à 4.

insert into public.appellations (id, slug, name, kind, organisme, region, bio, mots, color_1, color_2, status) values
  ('a0000000-0000-4000-a000-000000000001', 'coteaux-de-la-veze', 'Coteaux de la Vèze', 'aop',
   'ODG des Coteaux de la Vèze (démo)', 'Languedoc',
   'Des collines de schiste entre garrigue et rivière. Une quarantaine de familles y font du vin.',
   array['Schiste', 'Soleil', 'Garrigue'], '#FF8FAB', '#FFC79E', 'active');

insert into public.domaines (id, slug, name, first_name, region, bio, color_1, color_2, sales_enabled, status) values
  ('d0000000-0000-4000-a000-000000000001', 'mas-des-cigales', 'Mas des Cigales', 'Léa', 'Languedoc',
   'J''ai repris les vignes de mon grand-père en 2018. Je travaille en bio, à la main.', '#FF8FAB', '#FFC79E', true, 'active'),
  ('d0000000-0000-4000-a000-000000000002', 'domaine-pierre-plate', 'Domaine Pierre Plate', 'Karim', 'Languedoc',
   'Dix hectares sur le schiste. On vendange tôt le matin pour garder la fraîcheur.', '#B8A1FF', '#FFD6E0', true, 'active'),
  ('d0000000-0000-4000-a000-000000000003', 'clos-des-amandiers', 'Clos des Amandiers', 'Margaux', 'Languedoc',
   'Petit domaine familial, trois cuvées, beaucoup de patience.', '#7FD6B0', '#FFE58F', false, 'active'),
  ('d0000000-0000-4000-a000-000000000004', 'les-terrasses-de-jo', 'Les Terrasses de Jo', 'Jo', 'Languedoc',
   'Des vignes en terrasses qu''on entretient comme un jardin.', '#FFB36B', '#FF8FAB', true, 'active'),
  ('d0000000-0000-4000-a000-000000000005', 'domaine-du-vieux-pont', 'Domaine du Vieux Pont', 'Camille', 'Languedoc',
   'Au bord de la rivière depuis quatre générations. On fait aussi des bulles.', '#8FC8FF', '#C9B8FF', false, 'active');

insert into public.appellation_domaines (appellation_id, domaine_id, status, invited_by_odg)
select 'a0000000-0000-4000-a000-000000000001', id, 'active', true from public.domaines
where id::text like 'd0000000-0000-4000-a000-00000000000%';

insert into public.wines (domaine_id, appellation_id, slug, name, color, vintage, grapes, abv, price_cents, stock, mots, tags, pairings, label_style, is_published) values
  ('d0000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001', 'cigales-rouge-2023',
   'Chant des Cigales', 'rouge', 2023, 'Grenache, Syrah', 13.5, 1250, 120,
   array['Fruité', 'Gourmand', 'Souple'], array['pizza'], 'Pizza, burger, plat du quotidien',
   '{"bg":"#FF8FAB","ink":"#2A1033","motif":"waves"}', true),
  ('d0000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001', 'cigales-rose-2024',
   'Rosé de Léa', 'rose', 2024, 'Cinsault, Grenache', 12.5, 1090, 200,
   array['Léger', 'Agrume', 'Se boit frais'], array['apero', 'frais', 'petitprix'], 'Salades, grillades, apéro',
   '{"bg":"#FFE3EA","ink":"#FF3D6E","motif":"dots"}', true),
  ('d0000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001', 'pierre-plate-2022',
   'Schiste', 'rouge', 2022, 'Syrah, Mourvèdre', 14.0, 1850, 60,
   array['Intense', 'Épicé', 'Profond'], array[]::text[], 'Viande rouge, plats mijotés',
   '{"bg":"#2A1033","ink":"#FFC93C","motif":"lines"}', true),
  ('d0000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001', 'amandiers-blanc-2024',
   'Fleur d''Amandier', 'blanc', 2024, 'Roussanne, Vermentino', 12.5, 1400, 80,
   array['Floral', 'Frais', 'Rond'], array['apero', 'frais'], 'Poisson, fromage de chèvre',
   '{"bg":"#FFF6D6","ink":"#24102C","motif":"flower"}', true),
  ('d0000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001', 'terrasses-orange-2023',
   'Macération', 'orange', 2023, 'Grenache blanc', 12.0, 1600, 40,
   array['Surprenant', 'Sec', 'Abricot'], array[]::text[], 'Cuisine épicée, curry, tajine',
   '{"bg":"#FFB36B","ink":"#24102C","motif":"sun"}', true),
  ('d0000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001', 'terrasses-rouge-2024',
   'Petit Jo', 'rouge', 2024, 'Carignan', 12.5, 950, 150,
   array['Léger', 'Fruits rouges', 'Se boit frais'], array['pizza', 'frais', 'petitprix'], 'Pizza, charcuterie',
   '{"bg":"#FF3D6E","ink":"#FFFFFF","motif":"dots"}', true),
  ('d0000000-0000-4000-a000-000000000005', 'a0000000-0000-4000-a000-000000000001', 'vieux-pont-bulles',
   'Les Bulles du Pont', 'bulles', null, 'Chardonnay, Mauzac', 12.0, 1500, 90,
   array['Pétillant', 'Pomme', 'Vif'], array['apero', 'bulles', 'frais'], 'Apéro, huîtres, dessert aux fruits',
   '{"bg":"#C9B8FF","ink":"#2A1033","motif":"bubbles"}', true);
