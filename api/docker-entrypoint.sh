#!/bin/bash
set -e

until pg_isready -q -d "$DATABASE_URL"; do
  echo "waiting for postgres"
  sleep 1
done

for attempt in 1 2 3 4 5; do
  if bundle exec rake db:prepare && bundle exec rake db:seed; then
    break
  fi
  echo "schema not ready, retrying"
  sleep 4
done

exec "$@"
