SHELL := /bin/bash
.PHONY: up down clean logs psql migrate

up:
	 docker compose -f docker-compose.yml --env-file .env up -d db

down:
	 docker compose -f docker-compose.yml --env-file .env down

clean:
	 docker compose -f docker-compose.yml --env-file .env down -v

logs:
	 docker logs -f logistics-db

psql:
	 docker exec -it logistics-db psql -U ${PGUSER:-postgres} -d ${PGDATABASE:-logistics_dev}

migrate:
	 docker compose -f docker-compose.yml --env-file .env up --exit-code-from flyway flyway
