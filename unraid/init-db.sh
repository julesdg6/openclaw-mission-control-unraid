#!/bin/bash
# Initializes and starts PostgreSQL, creating the database/user when required.
# Data is persisted to /config/postgres so Unraid can map it to appdata.
set -euo pipefail

PGDATA="${PGDATA:-/config/postgres}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-mission_control}"

# Ensure the data directory is owned by the postgres system user.
mkdir -p "${PGDATA}"
chown -R postgres:postgres "${PGDATA}"
chmod 700 "${PGDATA}"

# Initialise the cluster if it does not already exist.
if [ ! -f "${PGDATA}/PG_VERSION" ]; then
    echo "[init-db] Initialising PostgreSQL data directory at ${PGDATA}"
    su -s /bin/bash postgres -c "initdb -D '${PGDATA}' --auth-host=md5 --auth-local=trust"
fi

# Start PostgreSQL in the background so we can run post-init SQL below.
echo "[init-db] Starting PostgreSQL"
su -s /bin/bash postgres -c "postgres -D '${PGDATA}' -c listen_addresses='127.0.0.1'" &
PG_PID=$!

# Wait for PostgreSQL to accept connections.
READY=0
for i in $(seq 1 30); do
    if su -s /bin/bash postgres -c "pg_isready -q -h 127.0.0.1" 2>/dev/null; then
        READY=1
        break
    fi
    echo "[init-db] Waiting for PostgreSQL to be ready (attempt ${i}/30)..."
    sleep 1
done

if [ "${READY}" -eq 0 ]; then
    echo "[init-db] ERROR: PostgreSQL did not become ready within 30 seconds. Exiting." >&2
    kill "${PG_PID}" 2>/dev/null || true
    exit 1
fi

# Create the role and database when they do not exist yet.
su -s /bin/bash postgres -c "psql -h 127.0.0.1 -tc \"SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'\"" \
    | grep -q 1 || \
    su -s /bin/bash postgres -c "psql -h 127.0.0.1 -c \"CREATE ROLE \\\"${POSTGRES_USER}\\\" WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}'\""

su -s /bin/bash postgres -c "psql -h 127.0.0.1 -tc \"SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'\"" \
    | grep -q 1 || \
    su -s /bin/bash postgres -c "psql -h 127.0.0.1 -c \"CREATE DATABASE \\\"${POSTGRES_DB}\\\" OWNER \\\"${POSTGRES_USER}\\\"\""

echo "[init-db] PostgreSQL is ready"

# Keep the process alive for supervisord (exits when postgres exits).
wait $PG_PID
