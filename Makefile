.PHONY: help init docker-up docker-down docker-restart docker-logs docker-rebuild
.PHONY: bench bench-clean log-clear alp alp-simple

# デフォルトターゲット
.DEFAULT_GOAL := help

# ヘルプ
help:
	@echo "Private ISU Makefile Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make init           - 初期データをダウンロード（初回のみ実行）"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up      - Dockerコンテナを起動"
	@echo "  make docker-down    - Dockerコンテナを停止・削除"
	@echo "  make docker-restart - Dockerコンテナを再起動"
	@echo "  make docker-rebuild - Dockerコンテナを再ビルド＆起動"
	@echo "  make docker-logs    - Dockerログをリアルタイム表示"
	@echo ""
	@echo "Benchmark:"
	@echo "  make bench          - ベンチマークを実行"
	@echo "  make bench-clean    - ログクリア後にベンチマーク実行"
	@echo ""
	@echo "Log Analysis:"
	@echo "  make alp            - アクセスログ分析（詳細版）"
	@echo "  make alp-simple     - アクセスログ分析（シンプル版）"
	@echo "  make log-clear      - nginxアクセスログをクリア"

# 初期セットアップ
init: webapp/sql/dump.sql.bz2 benchmarker/userdata/img

webapp/sql/dump.sql.bz2:
	cd webapp/sql && \
	curl -L -O https://github.com/catatsuy/private-isu/releases/download/img/dump.sql.bz2

benchmarker/userdata/img.zip:
	cd benchmarker/userdata && \
	curl -L -O https://github.com/catatsuy/private-isu/releases/download/img/img.zip

benchmarker/userdata/img: benchmarker/userdata/img.zip
	cd benchmarker/userdata && \
	unzip -qq -o img.zip

# Docker関連
docker-up:
	cd webapp && docker compose up -d
	@echo "Waiting for services to start..."
	@sleep 5
	@echo "Services are ready!"

docker-down:
	cd webapp && docker compose down

docker-restart:
	cd webapp && docker compose restart
	@echo "Services restarted!"

docker-rebuild:
	cd webapp && docker compose down
	cd webapp && docker compose up -d --build
	@echo "Services rebuilt and started!"

docker-logs:
	cd webapp && docker compose logs -f

# ベンチマーク関連
bench:
	docker run --rm --network host private-isu-benchmarker /bin/benchmarker -u /opt/userdata -t http://localhost

bench-clean: log-clear
	@echo "Logs cleared. Running benchmark..."
	@sleep 2
	docker run --rm --network host private-isu-benchmarker /bin/benchmarker -u /opt/userdata -t http://localhost

# ログ分析
log-clear:
	cd webapp && docker compose exec nginx sh -c "echo -n > /var/log/nginx/access.log"
	@echo "Nginx access log cleared!"

alp:
	./analyze-log.sh

alp-simple:
	./analyze-log-simple.sh
