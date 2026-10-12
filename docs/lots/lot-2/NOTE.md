# Lot 2 : espace vigneron

Fait :
- Connexion par lien magique (`/connexion`), routes `/pro` protégées.
- Création et modification du domaine (nom, prénom, région, bio, paire de couleurs). Statut « En attente de validation » tant qu'Allô Vino n'a pas validé.
- Demande d'adhésion à une appellation depuis `/pro`.
- Cuvées : création, modification, photo d'étiquette (bucket `labels`), appellation limitée à celles où le domaine est adhérent actif, case « Visible dans l'app ».
- Médias : choix Audio / Vidéo / Import. Enregistrement dans le navigateur (15 à 90 s, vidéo portrait 720p ~1,5 Mb/s), réécoute, envoi vers `medias-raw` puis ligne `medias` au statut `uploaded`. Suivi du statut rafraîchi toutes les 5 s pendant le traitement.

Écarts à valider :
- Enregistrement en « appuyer pour démarrer / appuyer pour arrêter » plutôt qu'en maintenant le bouton (pénible sur 60 s).
- Pastilles de couleur des vins (rouge #8E1B3B, blanc #F2E3A0) et 6 paires de couleurs de domaine : couleurs de contenu hors tokens.
- Import limité à 50 Mo (limite par fichier de l'offre gratuite Supabase) au lieu de 200 Mo.

Configuration Supabase nécessaire :
- Authentication > URL Configuration : Site URL `http://localhost:5173`, Redirect URLs `http://localhost:5173/**` et `http://192.168.2.63:5173/**`.

Reste à faire :
- Test du critère du lot : créer une cuvée et envoyer un audio de 60 s, puis une vidéo de 60 s (nécessite un vrai compte).
- La caméra et le micro ne marchent sur téléphone qu'en HTTPS : tester sur ordinateur, ou après déploiement Vercel.
