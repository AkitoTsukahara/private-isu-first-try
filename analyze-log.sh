#!/bin/bash
# nginxログをalpで解析するスクリプト

cd "$(dirname "$0")"

# デフォルトパラメータ
SORT="${1:-sum}"  # sum, avg, count, max
TAIL="${2:-1000}" # 取得する行数

echo "=== nginx access log analysis ==="
echo "Sort by: $SORT"

# ローカルファイルが存在する場合はそれを使用、なければdocker compose logsを使用
if [ -f "webapp/log/nginx/access.log" ]; then
  echo "Reading from: webapp/log/nginx/access.log (last $TAIL lines)"
  echo ""
  tail -n "$TAIL" webapp/log/nginx/access.log | \
    grep '^{' | \
    alp json \
      --sort "$SORT" \
      --reverse \
      --matching-groups '/posts/[0-9]+,/image/[0-9]+\.(jpg|png|gif),/@\w+,/comment,/login,/register,/logout,/admin/banned'
else
  echo "Reading from: docker compose logs (last $TAIL lines)"
  echo ""
  cd webapp
  docker compose logs nginx --no-log-prefix --tail "$TAIL" | \
    grep '^{' | \
    alp json \
      --sort "$SORT" \
      --reverse \
      --matching-groups '/posts/[0-9]+,/image/[0-9]+\.(jpg|png|gif),/@\w+,/comment,/login,/register,/logout,/admin/banned'
fi

echo ""
echo "Usage: $0 [sort_key] [tail_lines]"
echo "  sort_key: sum (default), avg, count, max"
echo "  tail_lines: number of log lines to analyze (default: 1000)"
