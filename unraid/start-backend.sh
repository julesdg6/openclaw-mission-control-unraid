#!/bin/bash
# Starts the FastAPI backend.
# Waits for PostgreSQL and Redis to be ready before launching.
set -euo pipefail

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-mission_control}"

export DATABASE_URL="postgresql+psycopg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@127.0.0.1:5432/${POSTGRES_DB}"
export REDIS_URL="redis://127.0.0.1:6379/0"
export RQ_REDIS_URL="${REDIS_URL}"
export DB_AUTO_MIGRATE="${DB_AUTO_MIGRATE:-true}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
export AUTH_MODE="${AUTH_MODE:-local}"
export LOCAL_AUTH_TOKEN="${LOCAL_AUTH_TOKEN:-}"
export BASE_URL="${BASE_URL:-http://localhost:8000}"
export CORS_ORIGINS="${CORS_ORIGINS:-http://localhost:3000}"

# Wait for PostgreSQL.
echo "[start-backend] Waiting for PostgreSQL..."
until pg_isready -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done

# Wait for Redis.
echo "[start-backend] Waiting for Redis..."
until redis-cli -h 127.0.0.1 ping 2>/dev/null | grep -q PONG; do sleep 1; done

echo "[start-backend] Starting backend API"
cd /opt/openclaw-mission-control/backend
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
