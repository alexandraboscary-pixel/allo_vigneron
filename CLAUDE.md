# Allô Vino
- Lire `README.md` avant tout : c'est le cahier de développement (données, RLS, routes, n8n, design system, conformité, lots).
- Travailler lot par lot (README section 12) et attendre la validation avant le lot suivant. Notes de lot dans `docs/lots/`.
- Front : `apps/web` (React 18 + Vite + TS, CSS modules + `src/styles/tokens.css`). Versions épinglées : installer avec `npm install --save-exact`.
- Supabase hébergé (pas de Docker ni de CLI sur la machine) : les migrations de `supabase/migrations/` sont collées dans l'éditeur SQL par l'utilisatrice.
- Variables : `apps/web/.env.local` (voir `.env.example`). Jamais de clé service côté front.
- Textes d'interface : français, tutoiement, sans jargon. Aucune couleur ni police hors tokens sans validation.
- Commandes (dans `apps/web`) : `npm run dev`, `npm run build`.
