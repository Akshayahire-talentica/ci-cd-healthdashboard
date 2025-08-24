# CI/CD Pipeline Health Dashboard (Local, Dockerized)

A local, dockerized dashboard that polls GitHub Actions for **all repos** you can access,
computes metrics (success rate, failure rate, average build time, last status), stores data
in Postgres, keeps **failed run logs** gzipped on disk for 7 days, and sends **Slack alerts**
on **every failed run** with `<!channel>` mention.

## What’s inside
- **backend/**: FastAPI + APScheduler poller + Slack alerts + SQLAlchemy models
- **frontend/**: React + Vite + Tailwind + Recharts
- **PostgreSQL**: persistent DB (volume `pgdata`)
- **Docker Compose**: one command to run locally

## Prerequisites
- Docker + Docker Compose
- A **GitHub Personal Access Token (classic)** with scopes: `repo`, `read:org`, `workflow`
- A **Slack Incoming Webhook** URL (enable in your Slack workspace)

## Quick start
1. Copy `.env.template` → `.env` and fill:
   - `GITHUB_TOKEN=` your new classic PAT (repo, read:org, workflow)
   - `SLACK_WEBHOOK_URL=` your incoming webhook URL
2. Build & run:
   ```bash
   docker compose up -d --build
   ```
3. Open:
   - **Frontend**: http://localhost:3000
   - **API** (docs): http://localhost:8080/docs

## Notes
- Polling defaults to **30s** and includes **all repos** and **all branches** you can read.
- Rate-limit safety: repo sharding, ETags, incremental fetch, backoff on 403.
- Logs are downloaded **only for failed jobs** and stored compressed in `/data/run-logs` (volume `runlogs`), deleted after **7 days**.
- Alerts: Slack webhook with `<!channel>` mention on **every failure**. You can turn this off (`ALERTS_ENABLED=false`) or change mentions (`ALERT_CHANNEL_MENTIONS=`).
- Keep your `.env` **out of Git**.

## Useful envs (see `.env.template`)
- `POLL_SHARDS` = spread repos across ticks (default 4)
- `MAX_RUNS_PER_REPO` = how many recent runs to scan each cycle (default 50)
- `BRANCH_FILTERS` = comma-separated (leave empty for all branches)
- `LOG_RETENTION_DAYS` = default 7

## Stop / clean
```bash
docker compose down
docker volume rm cicd_dashboard_pgdata cicd_dashboard_runlogs
```
