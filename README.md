# Allô Vino — Cahier de développement

> Le vin raconté par ceux qui le font.
> Le consommateur scanne une bouteille, écoute le vigneron parler de son vin sans jargon, puis le garde dans son book ou l'achète directement au domaine.
> Les ODG et interprofessions s'en servent pour faire connaître leur appellation et **tous** leurs vignerons.

Prototype de référence (UX et design) : `glou-prototype.html`, publié en artifact. Toute question d'interface se tranche en regardant ce prototype.

---

## 1. Concept et périmètre

### 1.1 Le produit en une phrase
Un mix Shazam + Instagram pour le vin : scan d'étiquette, audio ou vidéo court du vigneron (au choix), fil social des domaines, book personnel, achat direct au domaine. Vendu aux ODG et interprofessions comme outil de promotion collective de leur appellation.

### 1.2 Cibles
| Utilisateur | Besoin | Compte | Paie ? |
|---|---|---|---|
| ODG / interprofession / syndicat d'appellation | Faire connaître l'appellation aux 18-35 ans, donner de la visibilité à tous ses vignerons de façon égale, montrer l'utilité de la cotisation | Obligatoire (espace ODG) | **Oui, client principal** (abonnement annuel) |
| Vigneron / domaine | Raconter son vin sans faire de community management, vendre en direct, garder le contact client | Obligatoire (espace pro) | Non s'il adhère à un ODG client ; commission sur ventes si vente activée |
| Consommateur 18-35 ans | Choisir un vin sans s'y connaître, découvrir les gens derrière | Optionnel pour écouter, obligatoire pour book et achat | Non |
| Admin B.Conseil | Valider les domaines et les appellations, modérer les audios et vidéos | Obligatoire | — |

Cibles secondaires de vente : offices de tourisme et territoires labellisés « Vignobles & Découvertes » (budgets œnotourisme).

### 1.3 Modèle économique (B2B2C)
- **Abonnement annuel ODG**, par tranche de nombre de domaines adhérents. Il couvre l'accès de tous les vignerons de l'appellation à l'espace pro. Grille tarifaire à fixer après le pilote.
- **Commission sur les ventes directes**, facultative, uniquement pour les domaines qui activent la vente (Stripe Connect). L'ODG n'intervient pas dans la vente.
- **Kit physique** en option : stickers QR pour les domaines, présentoir QR collectif pour caveaux, salons et offices de tourisme.
- **Pilote** : un ODG, 10 à 20 domaines, une saison, tarif réduit. Objectif : chiffres réels (scans, écoutes complètes, abonnés) pour vendre aux ODG suivants.

### 1.4 Périmètre MVP (projet RNCP)
Inclus :
- Espace pro : fiche domaine, cuvées, enregistrement d'un audio **ou d'une vidéo** par cuvée, génération du QR code « Écoute le vigneron ».
- Pipeline média automatique (n8n) : conversion (vidéo en MP4 720p, audio en M4A), transcription, fiche courte générée par IA, validation par le vigneron.
- Page vin publique accessible par QR, sans compte.
- App consommateur : fil, explorer, scan, book, vignerons, profils domaines.
- **Page appellation publique** et **espace ODG** (adhésions, statistiques agrégées, QR collectif).
- Achat direct (Stripe en mode test), vendu par le domaine.

Hors MVP (feuille de route, section 12) : import CSV des adhérents, kit d'impression groupé, reconnaissance d'étiquette par image, e-étiquette réglementaire, réception des audios et vidéos par WhatsApp, recommandation IA conversationnelle, multilingue.

---

## 2. Stack technique

| Couche | Choix | Rôle |
|---|---|---|
| Front | React 18 + Vite + TypeScript | App consommateur, pages publiques, espace pro, espace ODG |
| Routing / data | React Router, TanStack Query, `@supabase/supabase-js` | Navigation, cache, accès données |
| Style | CSS variables (tokens section 9) + CSS modules | Respect strict du design system |
| PWA | `vite-plugin-pwa` | Installation sur l'écran d'accueil, cache hors ligne de la page vin |
| Back | Supabase (Postgres, Auth, Storage, RLS) | Données, comptes, fichiers audio et vidéo |
| Automatisation | n8n | Pipeline média, commandes, invitations, notifications, stats |
| Conversion | ffmpeg (sur le serveur n8n) | Vidéo en MP4 720p + image d'aperçu, extraction de la piste son, audio en M4A |
| Transcription | API Mistral (Voxtral) | Piste son du vigneron vers texte |
| IA texte | API Claude | Fiche courte, mots-clés, accords, contrôle de conformité du discours |
| Paiement | Stripe Checkout + Stripe Connect | Le domaine est le vendeur, la plateforme prend une commission |
| Scan | API `BarcodeDetector` du navigateur, repli sur une librairie de lecture QR | Lecture des QR « Écoute le vigneron » et QR collectifs |

Règle : épingler toutes les versions de dépendances (pas de `^` ni `latest` dans `package.json`).

---

## 3. Arborescence du projet

```
allo-vino/
├─ apps/web/                  # React + Vite
│  ├─ src/
│  │  ├─ app/                 # routes, layout, providers
│  │  ├─ features/
│  │  │  ├─ feed/             # fil + stories
│  │  │  ├─ explore/
│  │  │  ├─ scan/
│  │  │  ├─ wine/             # page vin + lecteur audio/vidéo + sous-titres
│  │  │  ├─ domaine/
│  │  │  ├─ appellation/      # page appellation publique
│  │  │  ├─ book/
│  │  │  ├─ checkout/
│  │  │  ├─ pro/              # espace vigneron
│  │  │  └─ odg/              # espace ODG
│  │  ├─ components/          # Bottle, Avatar, MediaPlayer, Sheet, Toast, TabBar
│  │  ├─ lib/                 # supabase client, formatters, age gate, ordre neutre
│  │  └─ styles/tokens.css
│  └─ .env.example
├─ supabase/
│  ├─ migrations/             # SQL de la section 5
│  └─ seed.sql                # 1 appellation, 5 domaines et 7 cuvées de démo (reprendre le prototype)
├─ n8n/
│  └─ workflows/              # exports JSON des workflows de la section 7
└─ README.md
```

---

## 4. Parcours clés

### 4.1 Consommateur, premier contact par QR (sans compte)
1. Scan du QR « Écoute le vigneron » collé sur la bouteille → `/w/:slug`.
2. Contrôle d'âge (une fois, mémorisé localement) : « As-tu 18 ans ou plus ? ».
3. Page vin : bouteille, nom, domaine, **appellation (lien vers sa page)**, 3 mots, **audio ou vidéo du vigneron avec sous-titres**, cépage, degré, accords, mention sanitaire.
4. Actions : Garder (demande de connexion par lien magique), Acheter (si le domaine vend en ligne), Suivre le domaine, Partager.
5. Bandeau discret : « Installe l'app pour retrouver ton book ».

### 4.2 Consommateur, QR collectif (caveau, salon, office de tourisme)
1. Scan du QR de l'appellation → `/a/:slug?src=qr_collectif`.
2. Contrôle d'âge.
3. Page appellation : audio ou vidéo de présentation de l'appellation, 3 mots, carte des domaines, liste des vignerons (ordre neutre, voir 8), cuvées par envie.
4. Le consommateur ouvre un vigneron ou un vin → parcours 4.1.

### 4.3 Consommateur dans l'app
Fil (stories audio et vidéo + posts) → page vin → garder / acheter. Book : onglets Gardés et Achetés. Explorer : envies (Pour l'apéro, Avec une pizza, À boire frais, Des bulles, Moins de 13 €) et appellations.

### 4.4 Vigneron
1. Inscription → création du domaine (statut `pending`, validé par l'admin), ou **arrivée par invitation de son ODG** (domaine pré-rattaché).
2. Demande d'adhésion à une ou plusieurs appellations (validée par l'ODG).
3. Création d'une cuvée (nom, couleur, millésime, **appellation**, cépage, degré, prix, stock, étiquette en photo).
4. **Choisir audio ou vidéo**, puis enregistrer dans le navigateur (bouton appuyer pour parler, ou caméra en mode portrait, 15 à 90 s), ou importer un fichier.
5. n8n traite le média → le vigneron reçoit une fiche proposée (transcription, 3 mots, accords) → il corrige et **publie**. Rien n'est publié sans sa validation.
6. Téléchargement du QR code (PNG et SVG) à imprimer sur la contre-étiquette ou en collerette.
7. Suivi : écoutes, scans, books, commandes.

### 4.5 ODG
1. Création de l'appellation par l'admin B.Conseil à la signature de l'abonnement, invitation du premier membre ODG.
2. Fiche appellation : présentation, couleurs, logo, **audio ou vidéo de présentation** (même pipeline WF1, validé par l'ODG).
3. Invitation des domaines adhérents par e-mail (WF4), validation des demandes d'adhésion.
4. Téléchargement du QR collectif de l'appellation.
5. Suivi : statistiques agrégées par domaine et pour l'appellation (scans, écoutes, écoutes complètes, books, abonnés). **L'ODG ne voit pas les ventes des domaines.**
6. Bilan mensuel par e-mail (WF5), à réutiliser en assemblée générale.

---

## 5. Modèle de données (Supabase)

### 5.1 Schéma

```sql
-- Extensions
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
  first_name text not null,            -- prénom affiché du vigneron
  region text not null,
  bio text,
  color_1 text not null default '#FF8FAB',
  color_2 text not null default '#FFC79E',
  avatar_path text,
  siret text,
  stripe_account_id text,
  sales_enabled boolean not null default false, -- vente en ligne activée par le domaine
  status text not null default 'pending' check (status in ('pending','active','suspended')),
  created_at timestamptz not null default now()
);

create table public.domaine_members (
  domaine_id uuid references public.domaines(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','editor')),
  primary key (domaine_id, user_id)
);

-- Appellations (clientes : ODG, interprofessions)
create table public.appellations (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,                  -- ex. « Saint-Chinian »
  kind text not null check (kind in ('aop','igp')),
  organisme text,                      -- nom de l'ODG ou de l'interprofession
  region text not null,
  bio text,
  mots text[] not null default '{}',
  color_1 text not null default '#FF8FAB',
  color_2 text not null default '#FFC79E',
  logo_path text,
  status text not null default 'pending' check (status in ('pending','active','suspended')),
  created_at timestamptz not null default now()
);

-- Équipe de l'ODG
create table public.appellation_members (
  appellation_id uuid references public.appellations(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','editor')),
  primary key (appellation_id, user_id)
);

-- Adhésion d'un domaine à une appellation
create table public.appellation_domaines (
  appellation_id uuid references public.appellations(id) on delete cascade,
  domaine_id uuid references public.domaines(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','active','left')),
  invited_by_odg boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (appellation_id, domaine_id)
);

-- Cuvées (rattachées à une appellation : un domaine peut produire dans plusieurs)
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
  mots text[] not null default '{}',         -- 3 mots simples
  tags text[] not null default '{}',         -- apero, pizza, frais, bulles, petitprix
  pairings text,
  label_image_path text,
  label_style jsonb,                          -- {bg, ink, motif} si pas de photo
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

-- Médias : audio ou vidéo, au choix de l'auteur (vigneron sur une cuvée, ou ODG sur l'appellation)
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
  segments jsonb,                             -- [{start, end, text}] si fournis par la transcription
  ai_draft jsonb,                             -- proposition IA en attente de validation
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
  appellation_id uuid references public.appellations(id) on delete cascade, -- scans de la page appellation
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

-- Index utiles
create index on public.wines (domaine_id);
create index on public.wines (appellation_id);
create index on public.appellation_domaines (domaine_id);
create index on public.medias (wine_id, status);
create index on public.medias (appellation_id, status);
create index on public.events (wine_id, type, created_at);
create index on public.events (appellation_id, type, created_at);
```

### 5.2 Fonctions d'appartenance

```sql
create or replace function public.is_member(d uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.domaine_members m where m.domaine_id = d and m.user_id = auth.uid());
$$;

create or replace function public.is_odg_member(a uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.appellation_members m where m.appellation_id = a and m.user_id = auth.uid());
$$;
```

### 5.3 RLS

> La version qui fait foi est `supabase/migrations/20261012000002_functions_rls.sql`. Elle durcit les règles ci-dessous : rôle, statuts, compte Stripe et montants de commande protégés par déclencheur ; créateur d'un domaine propriétaire automatiquement ; médias créés uniquement au statut `uploaded` ; cuvée rattachée seulement à une appellation dont le domaine est adhérent actif. Tests : `supabase/tests/rls_tests.sql`.

```sql
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

-- Profils : chacun gère le sien
create policy "profil_self" on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());

-- Domaines : lecture publique des domaines actifs, écriture par les membres
create policy "domaines_read"  on public.domaines for select using (status = 'active' or public.is_member(id));
create policy "domaines_write" on public.domaines for update using (public.is_member(id)) with check (public.is_member(id));
create policy "domaines_create" on public.domaines for insert with check (auth.uid() is not null);

create policy "members_read" on public.domaine_members for select using (user_id = auth.uid() or public.is_member(domaine_id));

-- Appellations : lecture publique si active, mise à jour par l'ODG.
-- Création et changement de statut : admin uniquement (clé service), à la signature de l'abonnement.
create policy "appellations_read"  on public.appellations for select using (status = 'active' or public.is_odg_member(id));
create policy "appellations_write" on public.appellations for update using (public.is_odg_member(id)) with check (public.is_odg_member(id));

create policy "odg_members_read" on public.appellation_members for select using (user_id = auth.uid() or public.is_odg_member(appellation_id));

-- Adhésions : publiques si actives ; le domaine demande ou quitte, l'ODG invite et valide
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

-- Cuvées : lecture publique si publiée, gestion par les membres du domaine
create policy "wines_read"  on public.wines for select using (is_published or public.is_member(domaine_id));
create policy "wines_write" on public.wines for all using (public.is_member(domaine_id)) with check (public.is_member(domaine_id));

-- Médias : lecture publique si publié, gestion par le domaine ou l'ODG concerné
create policy "medias_read" on public.medias for select using (
  status = 'published'
  or (domaine_id is not null and public.is_member(domaine_id))
  or (appellation_id is not null and public.is_odg_member(appellation_id))
);
create policy "medias_write" on public.medias for all
  using ((domaine_id is not null and public.is_member(domaine_id)) or (appellation_id is not null and public.is_odg_member(appellation_id)))
  with check ((domaine_id is not null and public.is_member(domaine_id)) or (appellation_id is not null and public.is_odg_member(appellation_id)));

-- Social : chacun gère ses lignes ; likes lisibles pour les compteurs
create policy "saves_self"   on public.saves   for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "follows_self" on public.follows for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "likes_read"   on public.likes   for select using (true);
create policy "likes_self"   on public.likes   for insert with check (user_id = auth.uid());
create policy "likes_del"    on public.likes   for delete using (user_id = auth.uid());

-- Statistiques : insertion anonyme, lecture brute par le domaine concerné.
-- L'ODG ne lit pas la table : il passe par la fonction agrégée appellation_stats (5.5).
create policy "events_insert" on public.events for insert with check (true);
create policy "events_read"   on public.events for select using (
  exists (select 1 from public.wines w where w.id = wine_id and public.is_member(w.domaine_id))
);

-- Commandes : le client voit les siennes, le domaine voit les siennes. L'ODG n'y a pas accès.
-- Aucune insertion côté client : les commandes sont créées par n8n (clé service) après paiement Stripe.
create policy "orders_read" on public.orders for select using (user_id = auth.uid() or public.is_member(domaine_id));
create policy "orders_ship" on public.orders for update using (public.is_member(domaine_id)) with check (public.is_member(domaine_id));
create policy "items_read"  on public.order_items for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.user_id = auth.uid() or public.is_member(o.domaine_id)))
);
```

### 5.4 Storage
| Bucket | Accès | Contenu |
|---|---|---|
| `medias-raw` | Privé (membres + service) | Enregistrements bruts, audio ou vidéo (200 Mo max) |
| `medias` | Public en lecture | Médias convertis et images d'aperçu, déposés par n8n (50 Mo max) |
| `labels` | Public en lecture | Photos d'étiquettes |
| `avatars` | Public en lecture | Photos des vignerons, logos des appellations |

Chemins :
- média de cuvée : `{domaine_id}/{wine_id}/{media_id}.{ext}` ;
- média d'appellation : `appellations/{appellation_id}/{media_id}.{ext}` ;
- après conversion (bucket `medias`) : `{…}/{media_id}.mp4` (vidéo) ou `.m4a` (audio), et `{…}/{media_id}.jpg` pour l'aperçu vidéo ;
- logo : `appellations/{appellation_id}/logo.png` dans `avatars`.

### 5.5 Statistiques agrégées pour l'ODG

```sql
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
```
Les `buy_click` et les commandes sont volontairement exclus : les ventes restent confidentielles entre le domaine et la plateforme.

---

## 6. Routes front

| Route | Accès | Écran |
|---|---|---|
| `/w/:slug` | Public | Page vin (entrée par QR) |
| `/d/:slug` | Public | Profil domaine |
| `/a/:slug` | Public | Page appellation (entrée par QR collectif) |
| `/` | Public | Fil (stories + posts) |
| `/explorer` | Public | Vins par envie, appellations |
| `/scan` | Public | Scanner (QR), demande la caméra |
| `/vignerons` | Public | Liste des domaines, filtrable par appellation |
| `/book` | Connecté | Gardés / Achetés |
| `/checkout/:wineId` | Connecté, majeur | Feuille d'achat → Stripe Checkout |
| `/pro` | Vigneron | Tableau de bord |
| `/pro/cuvees`, `/pro/cuvees/:id` | Vigneron | Fiche cuvée + enregistrement audio ou vidéo + validation IA |
| `/pro/appellations` | Vigneron | Adhésions aux appellations |
| `/pro/qr` | Vigneron | Génération des QR codes |
| `/pro/commandes` | Vigneron | Commandes, passage à « expédiée » |
| `/odg` | ODG | Tableau de bord de l'appellation (stats agrégées) |
| `/odg/fiche` | ODG | Fiche appellation + audio ou vidéo de présentation + validation IA |
| `/odg/domaines` | ODG | Adhérents : invitations, demandes, validation |
| `/odg/qr` | ODG | QR collectif (PNG, SVG) |
| `/admin` | Admin | Validation des domaines, création des appellations, modération des audios et vidéos |

Auth : lien magique par e-mail (Supabase Auth). Pas de mot de passe.

---

## 7. Workflows n8n

### WF1 — Traitement d'un média audio ou vidéo (cœur du produit)
Déclencheur : webhook base de données Supabase sur `insert` dans `medias`. Même traitement pour une cuvée ou une appellation.

Prérequis : n8n auto-hébergé avec ffmpeg installé (nœud Execute Command). n8n Cloud ne permet pas de lancer ffmpeg.

1. Passer `status` à `processing`.
2. Télécharger le fichier depuis `medias-raw` (clé service).
3. Convertir avec ffmpeg :
   - vidéo : MP4 H.264 + AAC, 720 px de haut maximum, ~1,5 Mb/s, lecture progressive (`-movflags +faststart`) ; image d'aperçu JPG à 1 s ;
   - audio : M4A AAC 96 kb/s ;
   - dans les deux cas, extraire la piste son pour la transcription. Refuser au-delà de 90 s.
   Le MP4 et le M4A se lisent sur iPhone comme sur Android, ce qui n'est pas le cas du WebM enregistré par Chrome.
4. Transcrire via l'API Mistral (modèle Voxtral de transcription, nom exact dans `MISTRAL_STT_MODEL`, à vérifier dans la documentation Mistral). Demander les horodatages par segment si l'API les fournit.
5. Appeler Claude avec le prompt 7.1 (cuvée) ou 7.2 (appellation) → JSON.
6. Déposer le fichier converti (et l'aperçu) dans `medias` sous un chemin provisoire non communiqué, écrire `transcript`, `segments`, `duration_s`, `ai_draft`, `compliance_flags`, puis `status = 'review'`.
7. Notifier l'auteur (e-mail) : « Ta vidéo / Ton audio pour {cuvée | appellation} est prêt à relire ».
8. En cas d'erreur : `status = 'error'` + notification.

Publication (déclenchée depuis `/pro` ou `/odg/fiche` à la validation, après la case « Ma vidéo respecte les règles » pour une vidéo) : `published_path` et `poster_path` renseignés, `status = 'published'`, mise à jour de `wines.mots` et `wines.pairings` (ou `appellations.mots`) avec la version validée.

### WF2 — Commande payée
Déclencheur : webhook Stripe `checkout.session.completed`.
1. Vérifier la signature Stripe.
2. Créer `orders` + `order_items` (clé service), décrémenter `wines.stock`.
3. E-mail au domaine (détail + adresse) et au client (confirmation).

### WF3 — Bilan hebdomadaire du domaine
Déclencheur : cron lundi 8 h. Pour chaque domaine actif : scans, écoutes complètes, books, ventes de la semaine → e-mail court.

### WF4 — Invitation des adhérents par l'ODG
Déclencheur : webhook appelé depuis `/odg/domaines` (liste d'e-mails, nom du domaine).
1. Vérifier que l'appelant est membre de l'appellation (JWT Supabase).
2. Pour chaque e-mail : créer l'utilisateur et le domaine `pending` s'ils n'existent pas (clé service), créer l'adhésion `active` avec `invited_by_odg = true`.
3. Envoyer le lien magique : « {organisme} t'invite sur Allô Vino pour faire écouter tes vins ».

### WF5 — Bilan mensuel de l'appellation
Déclencheur : cron le 1er du mois, 8 h. Pour chaque appellation active : scans (dont QR collectif), écoutes complètes, books, nouveaux abonnés, domaines actifs vs domaines sans audio publié → e-mail aux membres de l'ODG avec relance suggérée des domaines inactifs.

### 7.1 Prompt Claude (WF1, cuvée)

Système :
```
Tu aides un vigneron à présenter son vin à des consommateurs de 18 à 35 ans qui n'y connaissent rien.
À partir de la transcription de son audio ou de sa vidéo et de la fiche cuvée, produis UNIQUEMENT un objet JSON valide, sans texte autour.
Règles :
- Langage simple, zéro jargon œnologique.
- N'invente aucune information absente de la transcription ou de la fiche.
- Discours informatif uniquement (goût, origine, façon de faire, accords). Signale dans compliance_flags tout passage
  qui associe le vin à la fête, à la réussite sociale ou sexuelle, à la performance, ou qui incite à boire (loi Évin).
```

Utilisateur :
```
Fiche cuvée : {name}, {color}, {vintage}, {appellation}, {grapes}, {abv}
Transcription : {transcript}
```

Schéma de sortie attendu :
```json
{
  "mots": ["Fruité", "Léger", "Se boit frais"],
  "pairings": "Pizza, burger, plat du quotidien",
  "tags": ["pizza", "frais"],
  "post_caption": "Une phrase d'accroche pour le fil, 120 caractères max",
  "transcript_clean": "Transcription corrigée (ponctuation, noms propres), sans changer le sens",
  "compliance_flags": []
}
```
`tags` est limité à : `apero`, `pizza`, `frais`, `bulles`, `petitprix`.

### 7.2 Prompt Claude (WF1, appellation)

Système :
```
Tu aides un organisme d'appellation viticole à présenter son appellation à des consommateurs de 18 à 35 ans qui n'y connaissent rien.
À partir de la transcription de l'audio ou de la vidéo et de la fiche appellation, produis UNIQUEMENT un objet JSON valide, sans texte autour.
Règles :
- Langage simple, zéro jargon œnologique.
- N'invente aucune information absente de la transcription ou de la fiche.
- Ne cite aucun domaine en particulier : l'appellation parle pour tous ses vignerons.
- Discours informatif uniquement (terroir, histoire, cépages, savoir-faire, styles de vins). Signale dans compliance_flags
  tout passage qui associe le vin à la fête, à la réussite sociale ou sexuelle, à la performance, ou qui incite à boire (loi Évin),
  ainsi que toute mention d'un domaine nommé.
```

Utilisateur :
```
Fiche appellation : {name}, {kind}, {region}
Transcription : {transcript}
```

Schéma de sortie attendu :
```json
{
  "mots": ["Schiste", "Soleil", "Rouges gourmands"],
  "transcript_clean": "Transcription corrigée, sans changer le sens",
  "compliance_flags": []
}
```

---

## 8. Composants clés

- **MediaPlayer** : selon `kind`, lecteur audio (onde animée) ou lecteur vidéo (format portrait, image d'aperçu, lecture au toucher avec le son, `playsinline`, pas de lecture automatique) ; dans les deux cas sous-titres synchronisés (avec `segments` si disponibles, sinon répartition proportionnelle à la durée). Envoie les événements `play` et `complete`.
- **Recorder (pro et ODG)** : choix « Audio » ou « Vidéo » ; `MediaRecorder` (micro seul, ou caméra arrière/avant en portrait 720p à ~1,5 Mb/s), limite 90 s, réécoute avant envoi, upload vers `medias-raw`. Import de fichier accepté (200 Mo max).
- **Scanner** : `BarcodeDetector` (format `qr_code`) sur flux caméra ; repli sur une librairie de lecture QR si l'API n'existe pas ; saisie manuelle du code en dernier recours. Le QR vin encode `https://{domaine-app}/w/{slug}?src=qr`, le QR collectif `https://{domaine-app}/a/{slug}?src=qr_collectif`.
- **Bottle** : étiquette photo si `label_image_path`, sinon rendu SVG à partir de `label_style` (voir prototype).
- **AppellationHeader** : dégradé `color_1` / `color_2` de l'appellation, logo, nom, 3 mots, audio ou vidéo de présentation.
- **Ordre neutre** (`lib/neutralOrder.ts`) : sur la page appellation et la liste des vignerons, les domaines sont mélangés avec une graine qui change chaque jour (même ordre pour tous dans la journée, pas de domaine toujours en tête). Aucun tri par ventes, popularité ou ancienneté.
- **Sheet d'achat** : quantité, livraison (5,90 €, offerte dès 3 bouteilles, paramétrable par domaine), case « J'ai 18 ans ou plus » obligatoire + vérification de `profiles.birthdate`, mention « Vendu et expédié par {domaine} ». Affichée uniquement si `domaines.sales_enabled`.
- **AgeGate** : modal à la première visite, choix mémorisé en `localStorage`.

---

## 9. Design system (non négociable)

Repris du prototype. Toute nouvelle couleur ou police doit être validée avant usage.

```css
:root {
  --bg: #FFFFFF;      --surface: #F6F0F8;  --ink: #24102C;   --muted: #7A6A80;  --line: #ECE3EF;
  --pink: #FF3D6E;    /* action principale, bouton scan */
  --plum: #2A1033;    /* écran scan, carte audio/vidéo */
  --sun: #FFC93C;     /* mot en cours de lecture, succès */
  --blush: #FFE3EA;   /* puces "3 mots" */
  --font: "Bricolage Grotesque", ui-rounded, "Segoe UI", system-ui, sans-serif;
}
@media (prefers-color-scheme: dark) {
  :root { --bg:#170A1C; --surface:#24132B; --ink:#F7EEF8; --muted:#B39FBA; --line:#34213C; --blush:#3A1A2A; }
}
```

Règles :
- Une seule famille : Bricolage Grotesque (titres 800, interlettrage négatif ; texte 400 à 600).
- Chaque domaine a sa paire `color_1` / `color_2`, utilisée en dégradé sur ses visuels et son avatar. Même règle pour chaque appellation.
- Co-marquage : le logo de l'appellation n'apparaît que sur sa page et en pastille sur les cuvées rattachées. La police et les couleurs d'interface restent celles d'Allô Vino.
- Mobile d'abord, largeur max 440 px, barre d'onglets en bas avec le bouton Scanner central rose. L'espace ODG est consultable sur ordinateur (tableaux), mêmes tokens.
- Ton : tutoiement, phrases courtes, aucun jargon. Les boutons disent ce qu'ils font (« Garder », « Acheter, 12,50 € »).
- Mouvement : uniquement en réponse à une action (scan, lecture, ouverture de feuille). Respecter `prefers-reduced-motion`.

---

## 10. Conformité (à respecter dès le MVP)

### 10.1 Alcool et publicité (loi Évin)
- Contenu informatif uniquement : origine, cépage, goût, mode d'élaboration, accords. Pas d'association à la fête, à la séduction, au sport ou à la réussite. Le WF1 signale les passages à risque, l'auteur corrige avant publication.
- La loi Évin s'applique aussi à la communication collective de l'appellation : même contrôle sur les audios et vidéos ODG.
- Vidéo : l'IA ne contrôle que les paroles, pas les images. Avant de publier une vidéo, l'auteur coche « Ma vidéo respecte les règles », sous une liste courte : pas de personne en train de boire, pas de fête ni de soirée, pas de personne qui semble mineure, pas de sport ni de conduite. L'admin peut dépublier une vidéo à tout moment (modération après publication).
- Droit à l'image : si d'autres personnes que l'auteur apparaissent dans la vidéo, l'auteur confirme avoir leur accord (même case).
- Mention sanitaire sur chaque page vin, chaque page appellation et à l'achat : « L'abus d'alcool est dangereux pour la santé, à consommer avec modération. »
- Contrôle d'âge à l'entrée (y compris par QR collectif), et vérification de la majorité à l'achat (date de naissance + case à cocher horodatée dans `orders.age_confirmed_at`).
- Aucune publicité ciblant des mineurs, aucun contenu sur des pages ou comptes destinés aux mineurs.

### 10.2 E-étiquette réglementaire (ingrédients et nutrition)
Le QR code obligatoire des ingrédients (règlement UE 2021/2117) **ne doit pas** mener à une page contenant de la vente, du marketing ou de la collecte de données. Conséquences :
- Le QR « Écoute le vigneron » d'Allô Vino est un **QR distinct** de l'e-étiquette, avec son propre libellé sur la bouteille.
- Si Allô Vino propose plus tard l'e-étiquette en service, elle vit sur une route séparée `/e/:slug` : ingrédients et nutrition uniquement, aucun lien commercial, aucun traceur, aucun événement enregistré. Service vendable aux ODG pour l'ensemble de leurs adhérents.

### 10.3 Données personnelles (RGPD)
- Événements statistiques anonymes (pas d'`user_id` dans `events`).
- L'ODG ne reçoit que des statistiques agrégées, jamais de données de consommateurs ni de ventes des domaines.
- Bandeau de consentement si un outil d'analyse tiers est ajouté.
- Droit à l'effacement : suppression du compte → cascade sur `saves`, `follows`, `likes` ; commandes conservées pour obligations comptables.

### 10.4 Vente
- Le domaine est le vendeur (Stripe Connect) : CGV fournies par le domaine, plateforme intermédiaire avec commission.
- L'ODG n'est ni vendeur ni intermédiaire de vente.
- Vérifier avec un juriste les obligations de vente à distance d'alcool avant la mise en production réelle.

### 10.5 Promotion collective (contrat ODG)
- Neutralité : tous les adhérents ont le même traitement (ordre neutre, pas de mise en avant payante d'un domaine sur la page appellation).
- Le contrat ODG précise : périmètre (appellation, nombre de domaines), propriété des contenus (chaque audio ou vidéo appartient à son auteur), statistiques transmises, sortie (les domaines gardent leur compte si l'ODG résilie).
- Vérifier avec l'ODG que l'usage de son nom et de son logo est conforme à ses statuts et au cahier des charges de l'appellation.

---

## 11. Variables d'environnement

`apps/web/.env`
```
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
VITE_STRIPE_PUBLISHABLE_KEY=
VITE_APP_URL=
```

n8n (credentials, jamais côté front)
```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_JWT_SECRET=          # vérification de l'appelant dans WF4
MISTRAL_API_KEY=
MISTRAL_STT_MODEL=
ANTHROPIC_API_KEY=
CLAUDE_MODEL=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
SMTP_* (ou clé du service d'e-mail)
```

---

## 12. Plan de livraison par lots

| Lot | Contenu | Critère de validation |
|---|---|---|
| 0 | Repo, Vite + React + TS, Supabase local, tokens CSS, layout mobile + barre d'onglets | L'app s'ouvre en plein écran sur mobile avec les 5 onglets |
| 1 | Migrations SQL + RLS + seed (données du prototype + 1 appellation de démo) | Un utilisateur non membre ne peut ni lire une cuvée non publiée ni modifier un domaine ; un membre ODG ne peut ni lire les commandes ni les événements bruts (tests RLS) |
| 2 | Espace pro : domaine, cuvées, enregistreur audio et vidéo, upload | Un vigneron crée une cuvée et envoie un audio de 60 s, puis une vidéo de 60 s |
| 3 | WF1 n8n + écran de validation dans `/pro` | Audio ou vidéo envoyé → fiche proposée en moins de 2 min (3 min pour une vidéo) → publié après validation |
| 4 | Page vin publique `/w/:slug` + lecteur + sous-titres + QR téléchargeable | Le QR imprimé ouvre la page, l'audio ou la vidéo se lit avec ses sous-titres sur iPhone et Android |
| 5 | App consommateur : fil, stories, explorer, vignerons, profils, book, follow, like | Parcours complet du prototype avec données réelles |
| 5 bis | Appellation : page `/a/:slug`, ordre neutre, adhésions, espace `/odg` (fiche, audio ou vidéo, adhérents, QR collectif, stats agrégées) | Le QR collectif ouvre la page appellation ; l'ODG valide une adhésion et voit les stats de ses domaines, sans les ventes |
| 6 | Achat : feuille, Stripe Checkout (test), WF2 | Paiement test → commande visible côté client et côté domaine, stock décrémenté |
| 7 | WF3 bilan hebdo domaine + WF5 bilan mensuel ODG + tableaux de bord | Le domaine reçoit son e-mail du lundi, l'ODG son bilan du 1er |

Évolutions après MVP : WF4 invitations groupées et import CSV des adhérents, kit d'impression groupé des QR pour l'ODG, e-étiquette réglementaire séparée proposée aux ODG, offre offices de tourisme (parcours œnotouristique), reconnaissance d'étiquette par image, audios et vidéos reçus par WhatsApp, sommelier IA conversationnel branché sur les stocks, traduction et sous-titrage des audios et vidéos pour les touristes, vérification des images de vidéo par IA.

---

## 13. Consignes pour l'agent de développement

- Travailler **lot par lot, une étape à la fois**, et attendre la validation avant de passer à la suivante.
- Ne jamais exposer la clé service Supabase ni les clés API côté front.
- Toute écriture sensible (commandes, publication d'audio ou de vidéo, invitations ODG) passe par n8n ou une fonction serveur, jamais directement depuis le client.
- Neutralité ODG : aucun classement de domaines sur des pages d'appellation autre que l'ordre neutre de la section 8.
- Respecter le design system de la section 9 et le prototype ; signaler tout écart avant de l'introduire.
- Écrire les textes d'interface en français, au tutoiement, sans jargon.
- Chaque lot se termine par : migration à jour, `seed.sql` à jour, captures d'écran mobile, et une note de ce qui reste à faire.
