#!/bin/bash
# Initializes and starts PostgreSQL, creating the database/user when required.
# Data is persisted to /config/postgres so Unraid can map it to appdata.
set -euo pipefail

PGDATA="${PGDATA:-/config/postgres}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-mission_control}"

# On Debian, PostgreSQL binaries live under /usr/lib/postgresql/<version>/bin/
# and are not on the default PATH.  Discover the directory at runtime so the
# script works regardless of which PostgreSQL version was installed.
PG_BINDIR=$(find /usr/lib/postgresql -maxdepth 3 -name postgres -type f \
    -exec dirname {} + 2>/dev/null | sort -V | tail -1)
if [ -z "${PG_BINDIR}" ]; then
    echo "[init-db] ERROR: PostgreSQL binaries not found under /usr/lib/postgresql" >&2
    exit 1
fi
echo "[init-db] Using PostgreSQL binaries at ${PG_BINDIR}"

# Ensure the data directory is owned by the postgres system user.
mkdir -p "${PGDATA}"
chown -R postgres:postgres "${PGDATA}"
chmod 700 "${PGDATA}"

# Initialise the cluster if it does not already exist.
if [ ! -f "${PGDATA}/PG_VERSION" ]; then
    echo "[init-db] Initialising PostgreSQL data directory at ${PGDATA}"
    su -s /bin/bash postgres -c "${PG_BINDIR}/initdb -D '${PGDATA}' --auth-host=trust --auth-local=trust"
fi

# Start PostgreSQL in the background so we can run post-init SQL below.
# Listen on both local socket and 127.0.0.1 so that the application can
# connect via TCP once the setup below has completed.
echo "[init-db] Starting PostgreSQL"
su -s /bin/bash postgres -c "${PG_BINDIR}/postgres -D '${PGDATA}' -c listen_addresses='127.0.0.1'" &
PG_PID=$!

# Wait for PostgreSQL to accept connections via the local socket
# (auth-local=trust so no password needed at this stage).
READY=0
for i in $(seq 1 30); do
    if su -s /bin/bash postgres -c "pg_isready -q" 2>/dev/null; then
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

# Create the role if it does not exist yet.
# We use the local socket (no -h flag) so that auth-local=trust applies and
# no password is required for these maintenance commands.
# When POSTGRES_USER is "postgres" the role already exists after initdb.
if su -s /bin/bash postgres -c \
        "${PG_BINDIR}/psql -tc \"SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'\"" \
        | grep -q 1; then
    : # Role already exists; nothing to do.
else
    su -s /bin/bash postgres -c "${PG_BINDIR}/psql" <<EOSQL
CREATE ROLE "${POSTGRES_USER}" WITH LOGIN;
EOSQL
fi

if ! su -s /bin/bash postgres -c \
        "${PG_BINDIR}/psql -tc \"SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'\"" \
        | grep -q 1; then
    su -s /bin/bash postgres -c \
        "${PG_BINDIR}/psql -c \"CREATE DATABASE \\\"${POSTGRES_DB}\\\" OWNER \\\"${POSTGRES_USER}\\\"\""
fi

echo "[init-db] PostgreSQL is ready"

# Keep the process alive for supervisord (exits when postgres exits).
wait $PG_PID
