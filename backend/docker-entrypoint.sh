#!/bin/sh
set -e

if [ -n "${DATABASE_URL:-}" ]; then
  SPRING_DATASOURCE_URL="jdbc:${DATABASE_URL}"
  export SPRING_DATASOURCE_URL
fi

exec java -jar /app/app.jar