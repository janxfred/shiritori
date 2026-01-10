.PHONY: up down db

up:
	docker compose -f database/compose.yml up -d

down:
	docker compose -f database/compose.yml down --remove-orphans

db:
	docker compose -f database/compose.yml exec postgres psql -U user -d app_db
