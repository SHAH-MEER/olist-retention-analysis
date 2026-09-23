#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

DB_NAME="${DB_NAME:-commerce}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:?Set DB_PASSWORD in .env or the environment before running this script}"
DB_HOST="${DB_HOST:-localhost}"

if ! command -v psql >/dev/null 2>&1; then
    WIN_PG_BIN="/c/Program Files/PostgreSQL/18/bin"
    if [ -x "$WIN_PG_BIN/psql" ]; then
        export PATH="$WIN_PG_BIN:$PATH"
    fi
fi
if ! command -v psql >/dev/null 2>&1; then
    echo "ERROR: psql not found on PATH." >&2
    echo "Add your Postgres bin directory to PATH (e.g. C:\\Program Files\\PostgreSQL\\18\\bin on Windows) and retry." >&2
    exit 1
fi

echo "Creating database $DB_NAME if it doesn't exist..."
EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'")
if [ "$EXISTS" != "1" ]; then
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME"
fi

echo "Applying schema..."
PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$PROJECT_ROOT/sql/schema/tables.sql"
PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$PROJECT_ROOT/sql/schema/indexes.sql"

echo "Loading data..."
"$SCRIPT_DIR/load_data.sh"

if [ -f "$PROJECT_ROOT/sql/views/fact_orders.sql" ]; then
    echo "Building analyst-facing views..."
    PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$PROJECT_ROOT/sql/views/fact_orders.sql"
    PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$PROJECT_ROOT/sql/views/customer_retention_summary.sql"
fi

echo "Database setup complete."
