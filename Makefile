.PHONY: help build up down restart logs clean db-migrate db-seed test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build all Docker containers
	docker-compose build

up: ## Start all containers
	docker-compose up -d

down: ## Stop all containers
	docker-compose down

restart: ## Restart all containers
	docker-compose restart

logs: ## Show logs from all containers
	docker-compose logs -f

logs-backend: ## Show backend logs
	docker-compose logs -f backend

logs-frontend: ## Show frontend logs
	docker-compose logs -f frontend

logs-db: ## Show database logs
	docker-compose logs -f db

clean: ## Remove all containers, volumes, and images
	docker-compose down -v --rmi all

db-shell: ## Open PostgreSQL shell
	docker exec -it hotel-booking-db psql -U postgres -d hotel_booking

db-migrate: ## Run database migrations
	@echo "Running database migrations..."
	@for file in database/migrations/*.sql; do \
		echo "Executing $$file..."; \
		docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < $$file; \
	done
	@echo "Migrations completed!"

backend-shell: ## Open backend container shell
	docker exec -it hotel-booking-backend sh

frontend-shell: ## Open frontend container shell
	docker exec -it hotel-booking-frontend sh

ps: ## Show running containers
	docker-compose ps

rebuild: down build up ## Rebuild and restart all containers

dev: ## Start development environment
	@echo "Starting development environment..."
	@make up
	@echo "Waiting for database to be ready..."
	@sleep 5
	@echo "Development environment is ready!"
	@echo "Frontend: http://localhost:3000"
	@echo "Backend: http://localhost:8080"
	@echo "Database: localhost:5432"
