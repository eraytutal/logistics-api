#!/usr/bin/env bash
set -euo pipefail

SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:55432/logistics_dev \
SPRING_DATASOURCE_USERNAME=logistics_app \
SPRING_DATASOURCE_PASSWORD=app \
SPRING_FLYWAY_URL=jdbc:postgresql://localhost:55432/logistics_dev \
SPRING_FLYWAY_USER=logistics_owner \
SPRING_FLYWAY_PASSWORD=owner \
./mvnw spring-boot:run
