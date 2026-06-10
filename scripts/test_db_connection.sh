#!/bin/bash
# Test DB Connection
set -e
echo "=== Test DB Connection ==="
docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -c "SELECT version();" 2>&1
echo "PASS: PostgreSQL connection OK"
