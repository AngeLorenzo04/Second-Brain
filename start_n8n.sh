#!/usr/bin/env bash
set -e

sudo docker rm -f n8n 2>/dev/null || true
rm -f "$HOME"/.n8n/database.sqlite-wal "$HOME"/.n8n/database.sqlite-shm "$HOME"/.n8n/crash.journal
sudo chown -R 1000:1000 "$HOME"/.n8n

sudo docker run -d \
  --name n8n \
  --restart always \
  -p 5678:5678 \
  -v "$HOME"/.n8n:/home/node/.n8n \
  -e N8N_RUNNERS_GRANT_TOKEN_TTL=300 \
  -e N8N_RUNNERS_TASK_TIMEOUT=120 \
  -e N8N_RUNNERS_MAX_CONCURRENCY=10 \
  -e N8N_DISABLED_MODULES=mcp \
  -e N8N_DIAGNOSTICS_ENABLED=false \
  -e N8N_VERSION_NOTIFICATIONS_ENABLED=false \
  -e N8N_SECURE_COOKIE=false \
  -e EXECUTIONS_DATA_SAVE_ON_SUCCESS=none \
  -e EXECUTIONS_DATA_SAVE_ON_ERROR=all \
  -e EXECUTIONS_DATA_PRUNE=true \
  -e EXECUTIONS_DATA_MAX_AGE=12 \
  -e GENERIC_TIMEZONE=Europe/Rome \
  -e TZ=Europe/Rome \
  docker.n8n.io/n8nio/n8n
