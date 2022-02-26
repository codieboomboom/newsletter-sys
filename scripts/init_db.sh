#!/usr/bin/env bash
set -x
set -eo pipefail

# Check if necessary command line tools are installed?
if ! [ -x "$(command -v psql)" ]; then
    echo >&2 "Error: psql is not installed."
    exit 1
fi

if ! [ -x "$(command -v sqlx)" ]; then
    echo >&2 "Error: sqlx is not installed."
    echo >&2 "To install: "
    echo >&2 "    cargo install --version=0.5.7 sqlx-cli --no-default-features --features postgres"
    exit 1
fi

# Check if a custom user has been set for db, default to 'postgres'
DB_USER=${POSTGRES_USER:=postgres}
# Check if a custom password has been set, otherwise 'password'
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
# Check if a custom db name has been set, otherwise default to 'newsletter'
DB_NAME="${POSTGRES_DB:=newsletter}"
# Check if a custom port has been set, otherwise set to '5432'
DB_PORT="${POSTGRES_PORT:=5432}"

# Launch postgre using Docker
docker run \
    -e POSTGRES_USER=${DB_USER} \
    -e POSTGRES_PASSWORD=${DB_PASSWORD} \
    -e POSTGRES_DB=${DB_NAME} \
    -p "${DB_PORT}":5432 \
    -d postgres \
    postgres -N 1000
    # ^ increased maximum number of connections for testing purposes

# Container health check
# Keep pinging Postgres container until it's stable for accepting commands
export PGPASSWORD="${DB_PASSWORD}"
until psql -h "localhost" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c '\q'; do
    >&2 echo "Postgres is still unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up and running on port ${DB_PORT} - running migration now"

export DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
sqlx database create
sqlx migrate run

>&2 echo "DB has been migrated, ready to go!"