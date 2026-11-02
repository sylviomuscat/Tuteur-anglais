# Mind the Gap Voice — tuteur d'anglais à l'oral, gratuit

Ton ami parle dans le micro, la tutrice (Emma) répond à voix haute, sans rien toucher en mode « mains libres ».
Il y a aussi des jeux de rôle, un exercice de prononciation « Répète après moi », des corrections toutes les 4 répliques et un bilan avec 5 expressions à la fin de chaque séance.

Comment ça marche :

- **Le site** (dossier `site/`) est hébergé gratuitement sur Netlify. Le micro et la voix utilisent ce qui est intégré au navigateur : c'est gratuit.
- **Le cerveau** est un modèle d'IA open source (Gemma) qui tourne avec Ollama sur **ton serveur**. Caddy se place devant lui : il fournit le HTTPS et ne laisse passer que ton site avec la bonne clé.
- Aucun abonnement, aucune facture à la requête.

Le site marche déjà en **mode démo** (réponses toutes faites) tant que le serveur n'est pas branché. Tu peux donc le mettre en ligne tout de suite et tester le micro.

---

## Étape 1 — Mettre le site en ligne (10 min)

1. Le dépôt GitHub contient tout le projet : `site/` (le site), `server/` (le serveur) et ce README.
2. Sur Netlify : *Add new project* → *Import from GitHub* → choisis le dépôt. Pas de commande de build, dossier de publication : `site`.
3. Renomme le site dans *Project configuration* (par exemple `anglais-leo` → `https://anglais-leo.netlify.app`) et passe-le en *Public*, comme pour le tracker.
4. Ouvre-le dans **Chrome, Edge ou Safari** (Firefox ne sait pas faire la reconnaissance vocale) et autorise le micro.

## Étape 2 — Créer le serveur gratuit sur Oracle Cloud (20 à 30 min)

1. Crée un compte sur **cloud.oracle.com** (offre *Always Free*). Oracle demande une carte bancaire pour vérifier ton identité, mais ne la débite pas tant que tu restes sur les ressources « Always Free ».
   Choisis bien ta **région d'origine**, elle est définitive : *France Central (Paris)* ou *France South (Marseille)*.
2. *Compute → Instances → Create instance* :
   - Image : **Canonical Ubuntu 24.04**
   - Shape : **VM.Standard.A1.Flex** (Ampere, ARM), **4 OCPU et 24 Go de RAM** (le maximum gratuit)
   - Ajoute ta clé SSH (ou télécharge celle qu'Oracle génère)
   - Disque : 50 Go suffisent (jusqu'à 200 Go gratuits)

   Si Oracle répond *Out of capacity*, réessaie un peu plus tard ou change de domaine de disponibilité (*Availability domain*). C'est fréquent sur l'offre gratuite.
3. Ouvre les ports dans la console : *Networking → Virtual cloud networks → ton VCN → Security Lists → Default* → *Add Ingress Rules* :
   - Source `0.0.0.0/0`, TCP, port de destination **80**
   - Source `0.0.0.0/0`, TCP, port de destination **443**
4. Note l'**IP publique** de l'instance.

## Étape 3 — Installer le tuteur sur le serveur (10 min + téléchargement du modèle)

Depuis ton PC (PowerShell) :

```powershell
scp -i chemin\vers\ta-cle.key -r server ubuntu@IP_PUBLIQUE:~/tuteur
ssh -i chemin\vers\ta-cle.key ubuntu@IP_PUBLIQUE
```

Puis sur le serveur :

```bash
cd ~/tuteur
bash setup.sh
```

Le script installe Docker, ouvre le pare-feu interne de la machine (les images Ubuntu d'Oracle bloquent tout par défaut), génère une **clé secrète**, démarre Ollama et Caddy, puis télécharge le modèle.
À la fin, il affiche l'adresse (`https://IP-AVEC-TIRETS.sslip.io`) et la clé à mettre dans le site.

Indique ensuite l'adresse du site Netlify au serveur :

```bash
nano .env        # ALLOWED_ORIGIN=https://anglais-leo.netlify.app   (sans / à la fin)
sudo docker compose up -d
```

> `sslip.io` est un service gratuit qui transforme ton IP en nom de domaine (`1-2-3-4.sslip.io` → `1.2.3.4`). Caddy peut ainsi obtenir un vrai certificat HTTPS, obligatoire pour qu'un site en HTTPS puisse appeler ton serveur. Si tu prends un jour un vrai nom de domaine (ou un DuckDNS gratuit), il suffit de changer `DOMAIN` dans `.env`.

## Étape 4 — Brancher le site sur le serveur

Dans `site/config.js`, remplace :

```js
apiUrl: "https://IP-AVEC-TIRETS.sslip.io",
apiKey: "la-clé-affichée-par-setup.sh",
model: "gemma3:4b",
```

Commit sur GitHub : Netlify redéploie tout seul. Sur le site, *Réglages → Tester la connexion* doit afficher « Connexion réussie ».

---

## Choisir le modèle

Le serveur n'a pas de carte graphique, donc tout tourne sur le processeur. Plus le modèle est petit, plus il répond vite, mais moins il est fin.

| Modèle | Vitesse sur 4 OCPU ARM | Qualité |
|---|---|---|
| `llama3.2:3b` | rapide | correct pour discuter, corrections parfois approximatives |
| `gemma3:4b` (par défaut) | moyen | bon équilibre, bon anglais |
| `qwen2.5:7b` ou `llama3.1:8b` | lent (réponses de 10 à 20 s) | meilleur |

Pour changer : `sudo docker compose exec ollama ollama pull NOM`, puis mets le même nom dans `MODEL` (`.env`) et `model` (`config.js`).
La bibliothèque des modèles disponibles est sur ollama.com/library : il en sort régulièrement de nouveaux, plus performants à taille égale.

La voix commence à parler dès que la première phrase est prête, ce qui cache une bonne partie de l'attente.

## Commandes utiles sur le serveur

```bash
sudo docker compose ps                 # les deux conteneurs tournent ?
sudo docker compose logs -f caddy      # erreurs de certificat / requêtes refusées
sudo docker compose logs -f ollama     # le modèle
sudo docker compose pull && sudo docker compose up -d   # mise à jour
```

## Sécurité, en bref

- Ollama n'est **jamais** exposé directement : seul Caddy l'est, en HTTPS.
- Caddy refuse toute requête sans la clé, ainsi que toutes les routes sauf `/api/chat` et `/api/tags`. Personne ne peut donc télécharger ou supprimer de modèle à distance.
- La clé est visible dans le code du site (`config.js`), comme toute clé utilisée par un site sans serveur. Elle sert à empêcher n'importe qui d'utiliser ton serveur, pas à protéger un secret. Si quelqu'un en abuse, change `API_KEY` dans `.env` (`openssl rand -hex 24`), redémarre (`sudo docker compose up -d`) et mets la nouvelle clé dans `config.js`.

## Les limites à connaître

- La reconnaissance vocale fonctionne dans **Chrome, Edge et Safari**, pas dans Firefox. Dans Chrome, elle passe par les serveurs de Google.
- Le tuteur reçoit ce que la reconnaissance vocale a compris, pas le son. « Répète après moi » vérifie donc si **les mots sont reconnus**, ce qui est un bon indicateur de prononciation, sans être un vrai jury de phonétique.
- Un petit modèle gratuit discute bien, mais il est moins fiable que Claude ou ChatGPT pour expliquer finement la grammaire.
- La progression est enregistrée dans le navigateur de ton ami : elle reste sur son appareil.
