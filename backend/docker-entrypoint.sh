#!/bin/sh
set -e

if [ -n "${DB_HOST:-}" ]; then
  SPRING_DATASOURCE_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT:-5432}/${DB_NAME:-safety_wearable_db}"
  export SPRING_DATASOURCE_URL
fi

exec java -jar /app/app.jar