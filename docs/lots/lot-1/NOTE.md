# Lot 1 : base de données, RLS, données de démo

## À exécuter dans Supabase (éditeur SQL, dans cet ordre)
1. `supabase/migrations/20261012000001_schema.sql`
2. `supabase/migrations/20261012000002_functions_rls.sql`
3. `supabase/migrations/20261012000003_storage.sql`
4. `supabase/seed.sql`
5. `supabase/tests/rls_tests.sql` → tableau de 19 tests, `ok = true` attendu partout. Le script nettoie ses données de test.

## Fait
- Toutes les tables du README (section 5.1), dont appellations, équipe ODG et adhésions.
- RLS sur toutes les tables, fonction `appellation_stats` (stats agrégées ODG, sans ventes).
- Buckets `medias-raw` (privé, audio ou vidéo, 200 Mo), `medias`, `labels`, `avatars` avec leurs règles d'accès.
- Audio OU vidéo au choix : table `medias` avec `kind` (`audio` | `video`), chemins du fichier converti et de l'aperçu remplis par n8n.
- Profil créé automatiquement à l'inscription.
- Seed : 1 appellation, 5 domaines, 7 cuvées publiées.

## Écarts par rapport au README (failles corrigées)
- Un utilisateur pouvait se donner le rôle admin : le rôle n'est plus modifiable depuis l'app.
- Un vigneron pouvait activer lui-même son domaine, l'ODG son appellation : statuts réservés au serveur.
- Le créateur d'un domaine n'en devenait pas membre (aucune règle ne le permettait) : il en devient propriétaire automatiquement.
- Un vigneron pouvait marquer son média « publié » sans passer par n8n : création au statut `uploaded` uniquement, pas de modification côté client.
- Un domaine pouvait modifier le montant d'une commande : seul le passage « payée → expédiée » est permis.
- L'ODG ne voyait pas les domaines en attente qui demandent à adhérer : c'est corrigé.

## Reste à faire
- Remplacer les données de démo fictives par celles de `glou-prototype.html`.
- Brancher `apps/web/.env.local` sur le projet Supabase (utile dès le lot 2).
