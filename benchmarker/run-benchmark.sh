#!/bin/bash

# ベンチマーカー実行スクリプト（ulimit設定付き）
# 使い方: ./run-benchmark.sh [ターゲットURL]
# 例: ./run-benchmark.sh http://localhost:8080

# ターゲットURLの設定（デフォルト: http://localhost）
TARGET_URL=${1:-http://localhost}

# ulimit設定付きでベンチマーカーを実行
# --ulimit nofile=65536:65536 で最大ファイルディスクリプタ数を設定
docker run --rm \
  --network host \
  --ulimit nofile=65536:65536 \
  private-isu-benchmarker \
  /bin/benchmarker -u /opt/userdata -t "$TARGET_URL"

# 実行結果のステータスを返す
exit $?