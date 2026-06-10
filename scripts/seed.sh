#!/bin/bash
# Dark World — Seed Script
# Aplica dados de seed no banco

set -e

SEEDS_DIR="/opt/darkworld/database/seeds"

for file in "$SEEDS_DIR"/*.sql; do
  echo "[$(date)] Aplicando seed: $(basename "$file")"
  cat "$file" | docker exec -i darkworld-postgres psql -U darkworld_admin -d darkworld
done

echo "[$(date)] Seeds aplicados com sucesso."
