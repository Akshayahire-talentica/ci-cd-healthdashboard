# CI/CD Pipeline Health Dashboard (Local, Dockerized)

A local dashboard that polls **GitHub Actions** across all repositories you can access, stores run data in **PostgreSQL**, shows a **React + Tailwind** UI, and sends **Slack** alerts for **success** and **failure** (configurable). Runs entirely on your machine via **Docker Compose**—no cloud required.

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
16. [FAQ](#faq)  

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

... (continues with Ports, Build & Run, Verifying, Slack Alerts, Troubleshooting, etc.)
