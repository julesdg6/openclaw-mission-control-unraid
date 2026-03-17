#!/bin/bash
# Starts the FastAPI backend.
# Waits for PostgreSQL and Redis to be ready before launching.
set -euo pipefail

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-mission_control}"

export DATABASE_URL="postgresql+psycopg://${POSTGRES_USER}@127.0.0.1:5432/${POSTGRES_DB}"
export REDIS_URL="redis://127.0.0.1:6379/0"
export RQ_REDIS_URL="${REDIS_URL}"
export DB_AUTO_MIGRATE="${DB_AUTO_MIGRATE:-true}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
export AUTH_MODE="${AUTH_MODE:-local}"
export LOCAL_AUTH_TOKEN="${LOCAL_AUTH_TOKEN:-}"
export BASE_URL="${BASE_URL:-http://localhost:8000}"
export CORS_ORIGINS="${CORS_ORIGINS:-http://localhost:3000}"

# Wait for PostgreSQL and the target database/user to be accessible.
# pg_isready only confirms the server accepts connections; it does not
# verify that the role and database created by init-db.sh already exist.
# Connecting with the application credentials ensures both are present.
echo "[start-backend] Waiting for PostgreSQL..."
until psql -h 127.0.0.1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT 1" >/dev/null 2>&1; do sleep 1; done

# Wait for Redis.
echo "[start-backend] Waiting for Redis..."
until redis-cli -h 127.0.0.1 ping 2>/dev/null | grep -q PONG; do sleep 1; done

echo "[start-backend] Starting backend API"
cd /opt/openclaw-mission-control/backend
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
