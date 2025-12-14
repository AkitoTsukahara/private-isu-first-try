#!/bin/bash
# nginxログをalpで解析するスクリプト（シンプル版）
# ISUDON本のフォーマットに準拠

cd "$(dirname "$0")"

echo "=== nginx access log analysis (Simple) ==="
echo ""

# ローカルファイルが存在する場合はそれを使用、なければdocker compose logsを使用
if [ -f "webapp/log/nginx/access.log" ]; then
  cat webapp/log/nginx/access.log | \
    grep '^{' | \
    alp json \
      --sort sum \
      --reverse \
      --matching-groups "/posts/[0-9]+,/@\w+,/image/\d+" \
      --output count,method,uri,min,avg,max,sum
else
  cd webapp
  docker compose logs nginx --no-log-prefix --tail 10000 | \
    grep '^{' | \
    alp json \
      --sort sum \
      --reverse \
      --matching-groups "/posts/[0-9]+,/@\w+,/image/\d+" \
      --output count,method,uri,min,avg,max,sum
fi
