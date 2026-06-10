#!/bin/bash
set -e
echo "=== Test Redis Connection ==="
PONG=$(docker exec darkworld-redis redis-cli PING)
if [ "$PONG" = "PONG" ]; then echo "PASS: Redis PING OK"; else echo "FAIL"; exit 1; fi
