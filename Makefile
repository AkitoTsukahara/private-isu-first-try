.PHONY: help init docker-up docker-down docker-restart docker-logs docker-rebuild
.PHONY: bench bench-clean log-clear alp alp-simple
.PHONY: slow-query-digest slow-query-clear mysql-log-clear
.PHONY: save-alp save-slow-query save-analysis

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
	@echo "  make alp                 - アクセスログ分析（詳細版）"
	@echo "  make alp-simple          - アクセスログ分析（シンプル版）"
	@echo "  make log-clear           - nginxアクセスログをクリア"
	@echo ""
	@echo "MySQL Slow Query Analysis:"
	@echo "  make slow-query-digest   - スロークエリログを分析（pt-query-digest）"
	@echo "  make slow-query-clear    - スロークエリログをクリア"
	@echo "  make mysql-log-clear     - nginx + MySQLログを両方クリア"
	@echo ""
	@echo "Save Analysis Results:"
	@echo "  make save-alp            - alpの分析結果をファイルに保存"
	@echo "  make save-slow-query     - pt-query-digestの分析結果をファイルに保存"
	@echo "  make save-analysis       - alp + pt-query-digest両方の分析結果を保存"

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

# MySQLスロークエリ分析
slow-query-digest:
	@echo "=== MySQL Slow Query Analysis ==="
	@echo ""
	cd webapp && docker compose exec -T mysql cat /var/log/mysql/mysql-slow.log | pt-query-digest

slow-query-clear:
	cd webapp && docker compose exec mysql sh -c "echo -n > /var/log/mysql/mysql-slow.log"
	@echo "MySQL slow query log cleared!"

mysql-log-clear: log-clear slow-query-clear
	@echo "All logs cleared (nginx + MySQL)!"

# 分析結果を保存
save-alp:
	@mkdir -p output
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	OUTPUT_FILE="output/alp_$$TIMESTAMP.txt"; \
	echo "Saving alp analysis to $$OUTPUT_FILE ..."; \
	./analyze-log-simple.sh > "$$OUTPUT_FILE"; \
	echo "Saved to $$OUTPUT_FILE"

save-slow-query:
	@mkdir -p output
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	OUTPUT_FILE="output/pt-query-digest_$$TIMESTAMP.txt"; \
	echo "Saving pt-query-digest analysis to $$OUTPUT_FILE ..."; \
	cd webapp && docker compose exec -T mysql cat /var/log/mysql/mysql-slow.log | pt-query-digest > "../$$OUTPUT_FILE"; \
	echo "Saved to $$OUTPUT_FILE"

save-analysis: save-alp save-slow-query
	@echo ""
	@echo "=== Analysis results saved to output/ directory ==="
	@ls -lh output/ | tail -5
