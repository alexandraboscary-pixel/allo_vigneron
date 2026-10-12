# Lot 0 : socle

Fait :
- `apps/web` : Vite 7 + React 18 + TypeScript, React Router, TanStack Query, client Supabase (inactif sans `.env.local`), PWA installable (manifest, icônes, service worker).
- Tokens du design system (section 9), police Bricolage Grotesque, mode sombre automatique, `prefers-reduced-motion`.
- Layout mobile 440 px max, barre d'onglets à 5 entrées (Fil, Explorer, Scanner central rose, Vignerons, Book), écran scan sur fond `--plum`.
- Écrans vides pour chaque onglet.

Écarts signalés :
- Supabase local remplacé par un projet hébergé (pas de Docker).
- Barre d'onglets et icône dessinées sans le prototype `glou-prototype.html` : à aligner dès qu'il est dans le dépôt.

Reste à faire avant le lot 1 :
- Ajouter `glou-prototype.html` dans le dépôt.
- Créer le projet Supabase et remplir `apps/web/.env.local`.
