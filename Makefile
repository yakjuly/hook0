# Hook0 Local Development Makefile
# Usage: make <target>

.PHONY: db db-stop api worker frontend dev migrate clean help

# Environment variables for API (aligned with docker-compose.yaml)
export IP ?= 0.0.0.0
export PORT ?= 8081
export DATABASE_URL ?= postgres://postgres:postgres@localhost:5432/hook0
export RUST_LOG ?= info,sqlx=warn
export CORS_ALLOWED_ORIGINS ?= http://localhost:8001
export SMTP_CONNECTION_URL ?= smtp://localhost:1025
export EMAIL_SENDER_NAME ?= Priceline
export EMAIL_SENDER_ADDRESS ?= sender@getaroom.local
export APP_URL ?= http://localhost:8001
export MASTER_API_KEY ?= 414559eb-4c27-4ba8-9663-f63033bdf440
export BISCUIT_PRIVATE_KEY ?= bbea79cd66926b219b3219a3186decb36136d774dd7c35a8239e512090fa8854
export DISABLE_REGISTRATION ?= true
export SUPPORT_EMAIL_ADDRESS ?= support@priceline.com

# Environment variables for Output Worker (aligned with docker-compose.yaml)
export WORKER_NAME ?= default
export DISABLE_TARGET_IP_CHECK ?= true
export MAX_FAST_RETRIES ?= 5
export MAX_SLOW_RETRIES ?= 5

# Frontend environment
export API_ENDPOINT ?= http://localhost:8081/api/v1

help: ## Show this help
	@echo "Hook0 Local Development"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

db: ## Start PostgreSQL and Mailpit in Docker
	docker compose up -d postgres mailpit
	@echo "Waiting for PostgreSQL to be ready..."
	@until docker compose exec -T postgres pg_isready -U postgres -d hook0 > /dev/null 2>&1; do \
		sleep 1; \
	done
	@echo "PostgreSQL is ready!"

db-stop: ## Stop PostgreSQL and Mailpit
	docker compose stop postgres mailpit

api: ## Run API locally with cargo
	cd api && cargo run

worker: ## Run output-worker locally with cargo
	cd output-worker && cargo run

frontend: ## Run frontend dev server with npm
	cd frontend && npm run dev

frontend-install: ## Install frontend dependencies
	cd frontend && npm install

migrate: ## Run database migrations (requires sqlx-cli)
	cd api && cargo sqlx migrate run

build: ## Build all Rust components
	cargo build --release

clean: ## Stop all services and clean build artifacts
	docker compose down
	cargo clean

dev-api: db ## Start db and run API (convenience target)
	@$(MAKE) api

dev-worker: db ## Start db and run worker (convenience target)
	@$(MAKE) worker
