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
