#!/bin/sh
set -e

if [ -n "${DATABASE_URL:-}" ]; then
  database_location="${DATABASE_URL#*://}"
  database_location="${database_location#*@}"
  database_hostport="${database_location%%/*}"
  database_name="${DB_NAME:-${database_location#*/}}"
  database_port=5432

  case "$database_hostport" in
    *:*)
      database_port="${database_hostport##*:}"
      database_host="${database_hostport%:*}"
      ;;
    *) database_host="$database_hostport" ;;
  esac

  SPRING_DATASOURCE_URL="jdbc:postgresql://${database_host}:${database_port}/${database_name}"
  export SPRING_DATASOURCE_URL
fi

exec java -jar /app/app.jar