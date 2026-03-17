# openclaw-mission-control-unraid

Unraid Community Apps template and Docker image for [OpenClaw Mission Control](https://github.com/abhi1693/openclaw-mission-control) — an AI agent orchestration platform.

This repository packages the upstream application into a **single self-contained container** that includes PostgreSQL, Redis, the FastAPI backend, the RQ webhook worker, and the Next.js frontend. No external services are required.

---

## What is OpenClaw Mission Control?

OpenClaw Mission Control is an AI agent orchestration platform that lets you create, manage, and monitor AI agents and their webhook-driven workflows from a single browser UI.

---

## Docker Image

The image is published to the GitHub Container Registry on every push to `main` and daily:

```
ghcr.io/julesdg6/openclaw-mission-control-unraid:latest
```

### One-time repository setup for CI

GitHub's default Actions token permissions are **read-only**, which prevents `GITHUB_TOKEN` from creating a new package in the Container Registry on the first push.
Fix this with **one** of the two options below (option A is recommended):

**Option A — Add a `GHCR_TOKEN` repository secret** *(recommended — no repository settings change needed)*

You need a classic Personal Access Token (PAT) with the `write:packages` scope.  If you have already created one, skip straight to step 4.

1. Go to <https://github.com/settings/tokens/new> (GitHub → profile photo → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token**).
2. Give it a memorable note (e.g. `ghcr push – openclaw-mission-control-unraid`).
3. Tick the **`write:packages`** checkbox (this automatically selects `read:packages` too) and click **Generate token**.  Copy the token — you will not be able to see it again.
4. Open this repository on GitHub and click the **Settings** tab (the gear icon at the top of the page, not your profile settings).
5. In the left sidebar click **Secrets and variables** → **Actions**.
6. Click the **New repository secret** button.
7. In the **Name** field enter exactly: `GHCR_TOKEN`
8. Paste your token into the **Secret** field and click **Add secret**.

That is it.  The next push to `main` (or a manual run of the workflow via **Actions → Build and Push Docker Image → Run workflow**) will push the image successfully.

The CI workflow automatically prefers `GHCR_TOKEN` over `GITHUB_TOKEN` when the secret is present.

**Option B — Change the repository's default Actions token permissions**

1. In this repository go to **Settings → Actions → General → Workflow permissions**.
2. Select **Read and write permissions** and click **Save**.

---

## Installing on Unraid

> **Note:** This template is not yet listed in the Unraid Community Apps store.
> Use one of the methods below to install it manually.

### Method 1 — Download the template file (recommended for Unraid 7+)

In Unraid 7 and later the **Template repositories** field was removed from the Docker UI.
Instead, copy the template XML file directly to your Unraid server and then add the container through the UI.

1. Open an Unraid terminal (via the web UI: **Tools** → **Terminal**, or SSH into the server).
2. Run the following command to download the template to the correct location:
   ```bash
   wget -O /boot/config/plugins/dockerMan/templates-user/openclaw-mission-control-unraid.xml \
     https://raw.githubusercontent.com/julesdg6/openclaw-mission-control-unraid/main/unraid/openclaw-mission-control-unraid.xml
   ```
3. In the Unraid web UI go to **Docker** → **Add Container**.
4. In the **Template** drop-down select **openclaw-mission-control-unraid** (listed under *User Templates*).
5. Fill in the required variables (see the [Configuration](#configuration) table below) and click **Apply**.

### Method 2 — docker-compose / CLI

```yaml
version: "3.9"
services:
  openclaw-mission-control:
    image: ghcr.io/julesdg6/openclaw-mission-control-unraid:latest
    restart: unless-stopped
    ports:
      - "3000:3000"   # Next.js frontend
      - "8000:8000"   # FastAPI backend
    volumes:
      - /mnt/user/appdata/openclaw-mission-control:/config
    environment:
      AUTH_MODE: local
      LOCAL_AUTH_TOKEN: "<your-50-char-token>"
      BASE_URL: "http://<unraid-ip>:8000"
      CORS_ORIGINS: "http://<unraid-ip>:3000"
      NEXT_PUBLIC_API_URL: "auto"
```

---

## Configuration

| Variable | Default | Required | Description |
|---|---|---|---|
| `AUTH_MODE` | `local` | ✅ | Authentication mode: `local` (token) or `clerk` (Clerk JWT). |
| `LOCAL_AUTH_TOKEN` | _(empty)_ | ✅ when `AUTH_MODE=local` | Static auth token — must be at least 50 characters. |
| `BASE_URL` | `http://localhost:8000` | ✅ | Public URL of the backend API. Update to your Unraid IP if accessed from other devices (e.g. `http://192.168.1.10:8000`). |
| `CORS_ORIGINS` | `http://localhost:3000` | ✅ | Comma-separated allowed CORS origins. Update to your Unraid IP (e.g. `http://192.168.1.10:3000`). |
| `NEXT_PUBLIC_API_URL` | `auto` | ✅ | Browser-facing URL for the backend API. Use `auto` to target port 8000 on the same host, or supply an explicit URL. |
| `POSTGRES_DB` | `mission_control` | — | PostgreSQL database name. |
| `POSTGRES_USER` | `postgres` | — | PostgreSQL username. |
| `POSTGRES_PASSWORD` | `postgres` | — | PostgreSQL password (change to a strong value). |
| `LOG_LEVEL` | `INFO` | — | Backend log verbosity: `DEBUG`, `INFO`, `WARNING`, or `ERROR`. |

### Ports

| Port | Service |
|---|---|
| `3000` | Next.js frontend (browser UI) |
| `8000` | FastAPI backend (REST API) |

### Persistent storage

All data is written to `/config` inside the container. Map this to an Unraid appdata path, e.g. `/mnt/user/appdata/openclaw-mission-control`.

---

## Architecture

```
supervisord
├── PostgreSQL   (data → /config/postgres)
├── Redis        (in-memory; no persistence)
├── Backend API  (FastAPI on port 8000)
├── Worker       (RQ webhook worker)
└── Frontend     (Next.js on port 3000)
```

---

## Updating

Pull the latest image and recreate the container:

```bash
docker pull ghcr.io/julesdg6/openclaw-mission-control-unraid:latest
```

In Unraid, click **Check for Updates** in the Docker tab or use the Community Apps update manager.

---

## Links

- **Upstream project**: [abhi1693/openclaw-mission-control](https://github.com/abhi1693/openclaw-mission-control)
- **Docker image**: [ghcr.io/julesdg6/openclaw-mission-control-unraid](https://github.com/julesdg6/openclaw-mission-control-unraid/pkgs/container/openclaw-mission-control-unraid)
- **Issues / support**: [julesdg6/openclaw-mission-control-unraid/issues](https://github.com/julesdg6/openclaw-mission-control-unraid/issues)