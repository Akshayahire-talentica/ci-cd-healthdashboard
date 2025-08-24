CI/CD Pipeline Health Dashboard (Local, Dockerized)

A local, dockerized dashboard that polls GitHub Actions across all repos you can access, computes CI health metrics, stores data in PostgreSQL, shows a React + Tailwind UI, and sends Slack alerts on every failure with a log snippet.

What’s inside

backend/ — FastAPI API, APScheduler poller, GitHub client, Slack alerts, metrics, log storage

frontend/ — React + Vite + Tailwind + Recharts UI, served by Nginx (proxies /api to backend)

docker-compose.yml — orchestrates db, api, frontend

.env.template — copy to .env and fill required values

Volumes — pgdata (Postgres), runlogs (gzipped job logs)

Prerequisites

Docker + Docker Compose

GitHub Personal Access Token (classic) with scopes:

repo (private repos)

read:org (enumerate org repos)

workflow (read Actions runs/jobs/logs)

Slack Incoming Webhook URL (to post alerts)

Windows/WSL tip: build & run inside WSL Linux filesystem (e.g., ~/work/ci-cd-dashboard) for faster I/O than /mnt/c/....

Quick Start

Clone / unzip the repository and cd into it.

Create .env from template and fill values:

cp .env.template .env


Edit .env:

# ==== GitHub ====
GITHUB_TOKEN=your_new_pat_here
REPO_DISCOVERY_MODE=all          # all repos you can read
BRANCH_FILTERS=                  # empty = all branches
POLL_INTERVAL_SECONDS=30
POLL_SHARDS=4                    # shard repos across ticks (tune for rate limits)
MAX_RUNS_PER_REPO=50

# ==== Storage / Logs ====
LOG_STORAGE=disk
LOG_DIR=/data/run-logs
LOG_GZIP=true
LOG_RETENTION_DAYS=7
MAX_LOG_BYTES_PER_JOB=10485760   # 10MB/job log cap

# ==== Alerts (Slack Webhook) ====
ALERTS_ENABLED=true
ALERT_CHANNEL_MENTIONS=channel   # 'channel' -> <!channel>, 'here' -> <!here>, empty -> none
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ
ALERT_TITLE_PREFIX=[CI Failure]
ALERT_INCLUDE_LOG_SNIPPET=true
ALERT_LOG_SNIPPET_LINES=200

# ==== API / UI ====
TZ=Asia/Kolkata
JWT_SECRET=change_me_long_random
API_PORT=8080
FRONTEND_PORT=3001               # host port -> nginx:80

# ==== Database ====
POSTGRES_USER=ci
POSTGRES_PASSWORD=ci
POSTGRES_DB=ci_metrics
DATABASE_URL=postgresql://ci:ci@db:5432/ci_metrics


Build & run (enable BuildKit for speed/reliability):

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

docker compose up -d --build


Open the apps:

UI: http://localhost:${FRONTEND_PORT}
 → e.g., http://localhost:3001

API Docs (OpenAPI): http://localhost:${API_PORT}/docs
 → http://localhost:8080/docs

Health: http://localhost:${API_PORT}/health

How it works

Polling (every POLL_INTERVAL_SECONDS): the backend discovers all repos you can access, then shards them across cycles to stay within rate limits and fetches the latest runs (MAX_RUNS_PER_REPO) for each repo.

Metrics: success/failure rate, average duration, last build; daily time series.

Logs: only downloaded for failed jobs, gzip-compressed to /data/run-logs and retained for LOG_RETENTION_DAYS.

Alerts: on every failed run, a Slack message is posted with repo/branch, workflow, duration, failing jobs, and a log snippet (last N lines). Mention is controlled by ALERT_CHANNEL_MENTIONS.

Frontend: Nginx serves static build and proxies /api/* to api:8080.

Useful Commands

Start / stop / view logs

docker compose up -d
docker compose down
docker compose logs -f api
docker compose logs -f frontend
docker compose logs -f db


Rebuild specific service

docker compose build --no-cache frontend
docker compose build --no-cache api


Check container status

docker compose ps


Open a DB shell

docker exec -it $(docker ps -qf name=db) psql -U ci -d ci_metrics


Test API from host

curl "http://localhost:8080/api/metrics/overview?windowDays=7"
curl "http://localhost:8080/api/repos"


Clean volumes (DANGER: resets DB + logs)

docker compose down
docker volume rm cicd_dashboard_pgdata cicd_dashboard_runlogs

Frontend Features

Colorful KPI cards (success %, failure %, avg duration, last build)

Charts:

Bar: build outcomes by day (success, failure, other)

Line: average duration by day

Recent runs table; click Details to view jobs and a failure log snippet

Dark mode toggle

Auto-refresh toggle with interval selector

Manual refresh button and error states

Backend API (selected)

GET /api/repos — list monitored repos

GET /api/metrics/overview?repo&branch&windowDays — KPI summary

GET /api/metrics/timeseries?repo&branch&windowDays — daily counts + avg duration

GET /api/runs?repo&branch&limit — recent runs

GET /api/runs/{runId}/jobs — jobs in a run

GET /api/jobs/{jobId}/log — text of a job log (snippet)

Configuration Notes

Rate limits: GitHub API 5,000 req/hr/token. Adjust:

POLL_SHARDS (e.g. 8 or 12 for many repos)

MAX_RUNS_PER_REPO (lower if needed)

POLL_INTERVAL_SECONDS (increase to reduce calls)

Repo / branch filters:

REPO_DISCOVERY_MODE=all (default) auto-discovers all repos you can read.

BRANCH_FILTERS as comma-separated list (empty = all branches).

Slack:

Use a Slack Incoming Webhook and set SLACK_WEBHOOK_URL.

Mentions: ALERT_CHANNEL_MENTIONS=channel|here|"".

Security:

Keep .env out of Git. Never paste tokens publicly.

PAT scopes should be minimal: repo, read:org, workflow.

Troubleshooting

Frontend shows a blank page

Ensure Nginx proxy for /api/ is present (provided in frontend/Dockerfile via nginx.conf).

Open http://localhost:3001/api/metrics/overview
 — if you get JSON, proxy is good.

Check browser DevTools → Network tab for failing /api/ calls.

Port already in use

Change host port in .env:

FRONTEND_PORT=3001 (maps to container 80)

API_PORT=8080

Slow / stuck builds

Enable BuildKit:

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1


Build inside WSL Linux filesystem, not /mnt/c/....

Pre-pull base images:

docker pull python:3.11-slim node:20-alpine nginx:alpine postgres:15-alpine


No Slack alerts

Verify SLACK_WEBHOOK_URL in .env.

Check docker compose logs -f api for alert errors.

No data appears

Confirm GITHUB_TOKEN scopes & that repos actually have Actions runs.

Increase MAX_RUNS_PER_REPO and wait for next polling tick.
