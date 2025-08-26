# CI/CD Pipeline Health Dashboard (Local, Dockerized)

A local dashboard that polls **GitHub Actions** across all repositories you can access, stores run data in **PostgreSQL**, shows a **React + Tailwind** UI, and sends **Slack** alerts for **success** and **failure** (configurable). Runs entirely on your machine via **Docker Compose**—no cloud required.

---

## Table of Contents

1. [Overview](#overview)  
2. [Architecture](#architecture)  
3. [Prerequisites](#prerequisites)  
4. [Security Notes](#security-notes)  
5. [.env Configuration](#env-configuration)  
6. [Ports](#ports)  
7. [Build & Run](#build--run)  
8. [Verifying the Setup](#verifying-the-setup)  
9. [Slack Alerts Behavior](#slack-alerts-behavior)  
10. [GitHub Token & Rate Limits](#github-token--rate-limits)  
11. [Troubleshooting](#troubleshooting)  
12. [Common Docker Commands](#common-docker-commands)  
13. [Project Structure](#project-structure)  
14. [Updating & Rebuilding](#updating--rebuilding)  
15. [Uninstall / Cleanup](#uninstall--cleanup)  
 

---

## Overview

- **Ingestion**: Polls GitHub Actions every `POLL_INTERVAL_SECONDS` for **all repos** you can read (user + orgs), all branches (or filtered), last `MAX_RUNS_PER_REPO` runs per repo.  
- **Metrics**: Success/Failure rate, average build duration, last build status, daily time-series.  
- **Logs**: Downloads **failed job logs** only, gzips to disk, prunes after `LOG_RETENTION_DAYS`.  
- **Alerts**: Slack webhook alerts on **success** and/or **failure** (toggled independently), **idempotent** (sent at most once per run/type).  
- **UI**: React + Tailwind + Recharts, dark mode, auto-refresh, run details modal with job table & log snippet.  
- **Local-only**: Everything runs via Docker Compose on your machine.

---

## Architecture

```
Browser → Frontend (Nginx) → /api/* → FastAPI backend → PostgreSQL
                                   ↘︎ Slack Webhook (alerts)
GitHub Actions API → (polled by FastAPI scheduler)
```

- **frontend/** (React build served by Nginx, proxies `/api/*` to backend)  
- **backend/** (FastAPI + APScheduler + SQLAlchemy)  
- **db** (PostgreSQL)  
- **Volumes**: `pgdata` (DB), `runlogs` (gzipped logs)

---

## Prerequisites

- **Docker** and **Docker Compose** installed  
- **GitHub Personal Access Token (classic)** with scopes:
  - `repo` (private repos)
  - `read:org` (org repos)
  - `workflow` (read Actions runs/jobs/logs)
- **Slack Incoming Webhook URL** (to post alerts)
- **Windows/WSL users**: run and build inside the **WSL Linux filesystem** (e.g., `~/work/ci-cd-dashboard`) for much faster I/O than `/mnt/c/...`.

---

## Security Notes

- Never commit your `.env` (contains secrets).  
- Keep token scopes minimal (`repo`, `read:org`, `workflow`).  
- Revoke/rotate tokens that are exposed or no longer needed.  
- Slack Webhook URL is write-only; keep it private.

---

## .env Configuration

1) Copy the template and edit:
```bash
cp .env.template .env
```

2) Open `.env` and set values (examples below).

```env
# ==== GitHub ====
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
REPO_DISCOVERY_MODE=all
BRANCH_FILTERS=                 # empty = all branches, or "main,develop"
POLL_INTERVAL_SECONDS=30
POLL_SHARDS=4                   # shard repos across polling ticks (helps with rate limits)
MAX_RUNS_PER_REPO=50

# ==== Storage / Logs ====
LOG_STORAGE=disk
LOG_DIR=/data/run-logs
LOG_GZIP=true
LOG_RETENTION_DAYS=7
MAX_LOG_BYTES_PER_JOB=10485760  # 10MB cap per job log

# ==== Alerts (Slack Webhook) ====
ALERTS_ENABLED=true
ALERT_CHANNEL_MENTIONS=channel  # 'channel' -> <!channel>, 'here' -> <!here>, empty -> none
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ
ALERT_TITLE_PREFIX=[CI Pipeline]
ALERT_INCLUDE_LOG_SNIPPET=true
ALERT_LOG_SNIPPET_LINES=200

# Toggle each alert type independently:
ALERT_SUCCESS_ENABLED=true      # set false to silence success alerts
ALERT_FAILURE_ENABLED=true      # set false to silence failure alerts

# ==== API / UI ====
TZ=Asia/Kolkata
JWT_SECRET=change_me_long_random
API_PORT=8080
FRONTEND_PORT=3001              # host → container: 3001 → 80

# ==== Database ====
POSTGRES_USER=ci
POSTGRES_PASSWORD=ci
POSTGRES_DB=ci_metrics
DATABASE_URL=postgresql://ci:ci@db:5432/ci_metrics

# ==== Misc (proxy optional) ====
HTTP_PROXY=
HTTPS_PROXY=
```

---

## Ports

- **Frontend**: `http://localhost:${FRONTEND_PORT}` (default: **3001**)  
- **API**: `http://localhost:${API_PORT}` (default: **8080**)  
- **Nginx** in container always listens on `80`; host port is configurable via `FRONTEND_PORT`.

---

## Build & Run

```bash
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
docker compose up -d --build
```

Check status:
```bash
docker compose ps
```

---

## Verifying the Setup

- UI: `http://localhost:3001`  
- API Docs: `http://localhost:8080/docs`  
- Health: `http://localhost:8080/health`  

Smoke tests:
```bash
curl "http://localhost:8080/api/repos"
curl "http://localhost:8080/api/metrics/overview?windowDays=7"
```

---

## Slack Alerts Behavior

- Alerts are **idempotent** (once per run/type).  
- Only fire when `status=completed` and `conclusion in {success,failure}`.  
- Toggled via `.env` (`ALERT_SUCCESS_ENABLED`, `ALERT_FAILURE_ENABLED`).  
- Mentions: `ALERT_CHANNEL_MENTIONS=channel|here|""`.  
- Log snippet optional.

---

## GitHub Token & Rate Limits

- GitHub API limit: **5000 requests/hour**.  
- Tune with `POLL_SHARDS`, `MAX_RUNS_PER_REPO`, `POLL_INTERVAL_SECONDS`.  

---

## Troubleshooting

- **Frontend blank** → check Nginx proxy `/api/`.  
- **Ports in use** → change in `.env`.  
- **Slow build** → pre-pull base images, use WSL Linux FS.  
- **No Slack alerts** → verify URL & env.  
- **Duplicates** → ensure Alert table is present.  
- **No data** → check PAT scopes, repo has runs.

---

## Common Docker Commands

```bash
docker compose up -d
docker compose down
docker compose logs -f api
docker compose logs -f frontend
docker compose build --no-cache api
docker compose ps
```

---

## Project Structure

```
.
├─ backend/
│  ├─ app/
│  │  ├─ main.py
│  │  ├─ config.py
│  │  ├─ database.py
│  │  ├─ models.py
│  │  ├─ github.py
│  │  ├─ ingestor.py
│  │  ├─ metrics.py
│  │  ├─ routes.py
│  │  ├─ logs.py
│  │  └─ slack.py
│  └─ Dockerfile
├─ frontend/
│  ├─ src/
│  │  ├─ pages/Dashboard.tsx
│  │  └─ styles.css
│  ├─ nginx.conf
│  └─ Dockerfile
├─ docker-compose.yml
├─ .env.template
└─ README.md
```

---

## Updating & Rebuilding

```bash
docker compose build --no-cache api && docker compose up -d
docker compose build --no-cache frontend && docker compose up -d
docker compose up -d --build
```

---

## Uninstall / Cleanup

```bash
docker compose down
docker volume rm cicd_dashboard_pgdata cicd_dashboard_runlogs
```

---


