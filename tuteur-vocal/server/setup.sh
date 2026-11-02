#!/usr/bin/env bash
# Installation du serveur du tuteur sur une machine Ubuntu (prévu pour Oracle Cloud Always Free, ARM).
# Usage :  bash setup.sh            (relançable sans risque)
set -euo pipefail
cd "$(dirname "$0")"

echo "== 1/5 Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER" || true
fi

echo "== 2/5 Pare-feu de la machine (ports 80 et 443)"
# Les images Ubuntu d'Oracle bloquent tout par iptables, en plus des règles de la console Oracle.
for p in 80 443; do
  if ! sudo iptables -C INPUT -m state --state NEW -p tcp --dport "$p" -j ACCEPT 2>/dev/null; then
    sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport "$p" -j ACCEPT
  fi
done
if command -v netfilter-persistent >/dev/null 2>&1; then sudo netfilter-persistent save >/dev/null; fi

echo "== 3/5 Fichier .env"
if [ ! -f .env ]; then
  IP="$(curl -fsS https://api.ipify.org || curl -fsS https://ifconfig.me)"
  KEY="$(openssl rand -hex 24)"
  cat > .env <<EOF
DOMAIN=${IP//./-}.sslip.io
API_KEY=${KEY}
ALLOWED_ORIGIN=https://REMPLACE-MOI.netlify.app
MODEL=gemma3:4b
EOF
  echo "   .env créé. Pense à y mettre l'adresse de ton site Netlify (ALLOWED_ORIGIN)."
fi
set -a; . ./.env; set +a

echo "== 4/5 Démarrage des conteneurs"
sudo docker compose up -d

echo "== 5/5 Téléchargement du modèle $MODEL (quelques minutes la première fois)"
sudo docker compose exec -T ollama ollama pull "$MODEL"
# premier chargement en mémoire, pour que la première réponse ne soit pas trop lente
sudo docker compose exec -T ollama ollama run "$MODEL" "Say hello in five words." >/dev/null || true

cat <<EOF

C'est prêt. À mettre dans config.js du site :
  apiUrl: "https://$DOMAIN",
  apiKey: "$API_KEY",
  model:  "$MODEL",

Test rapide depuis n'importe quel ordinateur :
  curl -H "Authorization: Bearer $API_KEY" https://$DOMAIN/api/tags
EOF
if [ "$ALLOWED_ORIGIN" = "https://REMPLACE-MOI.netlify.app" ]; then
  echo
  echo "ATTENTION : ALLOWED_ORIGIN n'est pas encore rempli dans .env."
  echo "Mets l'adresse de ton site Netlify, puis lance : sudo docker compose up -d"
fi
