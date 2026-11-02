test line# Mind the Gap Voice — tuteur d'anglais à l'oral, gratuit

Ton ami parle dans le micro, la tutrice (Emma) répond à voix haute, sans rien toucher en mode « mains libres ».
Il y a aussi des jeux de rôle, un exercice de prononciation « Répète après moi », des corrections toutes les 4 répliques et un bilan avec 5 expressions à la fin de chaque séance.

Comment ça marche :

- **Le site** (dossier `site/`) est hébergé gratuitement sur Netlify. Le micro et la voix utilisent ce qui est intégré au navigateur : c'est gratuit.
- **Le cerveau** est un modèle d'IA open source (Gemma) qui tourne avec Ollama sur **ton serveur**. Caddy se place devant lui : il fournit le HTTPS et ne laisse passer que ton site avec la bonne clé.
- Aucun abonnement, aucune facture à la requête.

Le site marche déjà en **mode démo** (réponses toutes faites) tant que le serveur n'est pas branché. Tu peux donc le mettre en ligne tout de suite et tester le micro.

---

## Étape 1 — Mettre le site en ligne (10 min)

1. Crée un dépôt GitHub (par exemple `tuteur-anglais`) et mets-y le **contenu** du dossier `site/` (`index.html` et `config.js` à la racine).
2. Sur Netlify : *Add new project* → *Import from GitHub* → choisis le dépôt. Pas de commande de build, dossier de publication : `/`.
3. Renomme le site dans *Project configuration* (par exemple `anglais-leo` → `https://anglais-leo.netlify.app`) et passe-le en *Public*, comme pour le tracker.
4. Ouvre-le dans **Chrome, Edge ou Safari** (Firefox ne sait pas faire la reconnaissance vocale) et autorise le micro.
# Tuteur d'anglais vocal
