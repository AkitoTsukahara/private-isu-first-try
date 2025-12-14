#!/bin/bash
# nginxログをalpで解析するスクリプト（シンプル版）
# ISUDON本のフォーマットに準拠

cd "$(dirname "$0")/webapp"

echo "=== nginx access log analysis (Simple) ==="
echo ""

docker compose logs nginx --no-log-prefix --tail 10000 | \
  grep '^{' | \
  alp json \
    --sort sum \
    --reverse \
    --matching-groups "/posts/[0-9]+,/@\w+,/image/\d+" \
    --output count,method,uri,min,avg,max,sum
