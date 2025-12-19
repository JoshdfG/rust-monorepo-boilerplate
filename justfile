# build:
#     cargo build --workspace
#
# test:
#     cargo test --workspace
#
# run-api:
#     cargo run --bin api
#
# run-cli:
#     cargo run --bin cli
#
# check: fmt clippy test
#
# fmt:
#     cargo fmt --all -- --check
#
# clippy:
#     cargo clippy --workspace --all-targets -- -D warnings
#
# Fixes the formatting of the workspace
fmt-native-fix:
  cargo +nightly fmt --all

# Check the formatting of the workspace
fmt-native-check:
  cargo +nightly fmt --all -- --check

run-watch:
  cargo watch -x run
#.PHONY: run build stop clean logs restart shell db-shell check-env

# Check if .env.docker exists
check-env:
	@if [ ! -f .env.docker ]; then \
		echo "Error: .env.docker not found!"; \
		echo "Please create .env.docker with DATABASE_URL pointing to 'db' service"; \
		exit 1; \
	fi

# Run in development mode
run: check-env
	docker compose -f docker-compose.build.yml up

# Build and run (recommended for first time)
build: check-env
	docker compose -f docker-compose.build.yml up --build

# Stop containers
stop:
	docker compose -f docker-compose.build.yml down

# Clean everything (containers, volumes, images)
clean:
	docker compose -f docker-compose.build.yml down -v --rmi all
	rm -rf target/

# View logs
logs:
	docker compose -f docker-compose.build.yml logs -f

# View only wallet_impl logs
logs-app:
	docker compose -f docker-compose.build.yml logs -f wallet_impl

# View only db logs
logs-db:
	docker compose -f docker-compose.build.yml logs -f db

# Restart services
restart:
	docker compose -f docker-compose.build.yml restart

# Open shell in wallet_impl container
shell:
	docker compose -f docker-compose.build.yml exec wallet_impl bash

# Open PostgreSQL shell
db-shell:
	docker compose -f docker-compose.build.yml exec db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

# Run in detached mode
run-d: check-env
	docker compose -f docker-compose.build.yml up -d

# Rebuild without cache (use when dependencies change)
rebuild: check-env
	docker compose -f docker-compose.build.yml build --no-cache
	docker compose -f docker-compose.build.yml up

# Test database connection
test-db:
	docker compose -f docker-compose.build.yml exec db pg_isready -U $(POSTGRES_USER) -d $(POSTGRES_DB)

# Show running containers
ps:
	docker compose -f docker-compose.build.yml ps

# Show container stats
stats:
	docker stats $(shell docker compose -f docker-compose.build.yml ps -q)

# Security audit (requires cargo-audit)
audit:
	@echo "🔒 Running security audit..."
	@command -v cargo-audit >/dev/null 2>&1 || { \
		echo "cargo-audit not found. Installing..."; \
		cargo install cargo-audit; \
	}
	cargo audit

# Security check (less strict for CI)
security:
	@echo "🔒 Running security check..."
	@command -v cargo-audit >/dev/null 2>&1 || { \
		echo "cargo-audit not found. Installing..."; \
		cargo install cargo-audit; \
	}
	cargo audit --deny unsound --deny yanked || echo "⚠️  Warnings found (see SECURITY.md)"

# Update security advisory database
audit-update:
	@command -v cargo-audit >/dev/null 2>&1 || cargo install cargo-audit
	cargo audit --update
