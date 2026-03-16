#!/bin/bash
# Starts the RQ webhook worker.
# Waits for PostgreSQL and Redis to be ready before launching.
set -euo pipefail

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-mission_control}"

export DATABASE_URL="postgresql+psycopg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@127.0.0.1:5432/${POSTGRES_DB}"
export REDIS_URL="redis://127.0.0.1:6379/0"
export RQ_REDIS_URL="${REDIS_URL}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
export AUTH_MODE="${AUTH_MODE:-local}"
export LOCAL_AUTH_TOKEN="${LOCAL_AUTH_TOKEN:-}"
export BASE_URL="${BASE_URL:-http://localhost:8000}"
export RQ_QUEUE_NAME="${RQ_QUEUE_NAME:-default}"
export RQ_DISPATCH_THROTTLE_SECONDS="${RQ_DISPATCH_THROTTLE_SECONDS:-2.0}"
export RQ_DISPATCH_MAX_RETRIES="${RQ_DISPATCH_MAX_RETRIES:-3}"

# Wait for PostgreSQL.
echo "[start-worker] Waiting for PostgreSQL..."
until pg_isready -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done

# Wait for Redis.
echo "[start-worker] Waiting for Redis..."
until redis-cli -h 127.0.0.1 ping 2>/dev/null | grep -q PONG; do sleep 1; done

echo "[start-worker] Starting webhook worker"
cd /opt/openclaw-mission-control/backend
exec python /opt/openclaw-mission-control/scripts/rq-docker worker
