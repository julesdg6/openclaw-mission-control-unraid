#!/bin/bash
# Starts the Next.js frontend server.
set -euo pipefail

export NODE_ENV=production
export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-auto}"
export NEXT_PUBLIC_AUTH_MODE="${AUTH_MODE:-local}"

echo "[start-frontend] Starting Next.js frontend"
cd /opt/openclaw-mission-control/frontend
exec npm run start -- --hostname 0.0.0.0 --port 3000
