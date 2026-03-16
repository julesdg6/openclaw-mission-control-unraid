# syntax=docker/dockerfile:1
# Single-container Unraid image for OpenClaw Mission Control.
# Bundles PostgreSQL, Redis, the backend API, the RQ webhook worker,
# and the Next.js frontend under supervisord.

FROM python:3.12-slim

# Build-time argument injected by the CI workflow.
ARG UPSTREAM_VERSION=unknown
LABEL org.opencontainers.image.version="${UPSTREAM_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# ── system dependencies ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    redis-server \
    postgresql \
    postgresql-contrib \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 (LTS) via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python dependency management
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# ── copy source ────────────────────────────────────────────────────────────────
WORKDIR /opt/openclaw-mission-control
COPY . /opt/openclaw-mission-control

# ── backend Python dependencies ────────────────────────────────────────────────
WORKDIR /opt/openclaw-mission-control/backend
RUN uv sync --frozen --no-dev
ENV PATH="/opt/openclaw-mission-control/backend/.venv/bin:${PATH}"

# ── frontend Node dependencies & production build ─────────────────────────────
WORKDIR /opt/openclaw-mission-control/frontend
RUN npm ci && npm run build

WORKDIR /opt/openclaw-mission-control

# ── supervisord & start scripts ────────────────────────────────────────────────
COPY unraid/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY unraid/init-db.sh       /usr/local/bin/init-db.sh
COPY unraid/start-backend.sh /usr/local/bin/start-backend.sh
COPY unraid/start-worker.sh  /usr/local/bin/start-worker.sh
COPY unraid/start-frontend.sh /usr/local/bin/start-frontend.sh

RUN chmod +x /usr/local/bin/init-db.sh \
              /usr/local/bin/start-backend.sh \
              /usr/local/bin/start-worker.sh \
              /usr/local/bin/start-frontend.sh

# ── exposed ports ──────────────────────────────────────────────────────────────
# 3000 – Next.js frontend UI
# 8000 – FastAPI backend
EXPOSE 3000
EXPOSE 8000

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
