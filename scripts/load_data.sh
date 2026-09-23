#!/bin/bash
set -euo pipefail

# Load DB connection settings from .env if present, otherwise use defaults.
# Copy .env.example to .env and adjust as needed.
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

RAW_DIR="$PROJECT_ROOT/data/raw"

psql_exec() {
    PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" "$@"
}

# Guard against loading Git LFS pointer stubs instead of real CSVs.
check_real_csv() {
    local file=$1
    local size
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")
    if [ "$size" -lt 1024 ]; then
        echo "ERROR: $file is only ${size} bytes - looks like a Git LFS pointer, not real data." >&2
        echo "Download the dataset (e.g. via kagglehub) into data/raw before running this script." >&2
        exit 1
    fi
}

load_csv() {
    local csv_file=$1
    local table_name=$2

    check_real_csv "$RAW_DIR/$csv_file"

    echo "Truncating and loading $csv_file into $table_name..."
    psql_exec <<EOF
    TRUNCATE TABLE $table_name CASCADE;
    \copy $table_name FROM '$RAW_DIR/$csv_file' WITH (FORMAT csv, HEADER true);
EOF
}

# Drop FK constraints so load order doesn't matter, restored at the end.
echo "Dropping foreign key constraints..."
psql_exec -c "ALTER TABLE order_items DROP CONSTRAINT IF EXISTS order_items_product_id_fkey;"
psql_exec -c "ALTER TABLE order_items DROP CONSTRAINT IF EXISTS order_items_order_id_fkey;"
psql_exec -c "ALTER TABLE order_payments DROP CONSTRAINT IF EXISTS order_payments_order_id_fkey;"
psql_exec -c "ALTER TABLE order_reviews DROP CONSTRAINT IF EXISTS order_reviews_order_id_fkey;"
psql_exec -c "ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_customer_id_fkey;"

load_csv "olist_customers_dataset.csv" "customers"
load_csv "olist_geolocation_dataset.csv" "geolocation"
load_csv "olist_sellers_dataset.csv" "sellers"
load_csv "olist_products_dataset.csv" "products"
load_csv "product_category_name_translation.csv" "product_category_translation"
load_csv "olist_orders_dataset.csv" "orders"
load_csv "olist_order_items_dataset.csv" "order_items"
load_csv "olist_order_payments_dataset.csv" "order_payments"
load_csv "olist_order_reviews_dataset.csv" "order_reviews"

echo "Restoring foreign key constraints..."
psql_exec -c "ALTER TABLE order_items ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(product_id);"
psql_exec -c "ALTER TABLE order_items ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(order_id);"
psql_exec -c "ALTER TABLE order_payments ADD CONSTRAINT order_payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(order_id);"
psql_exec -c "ALTER TABLE order_reviews ADD CONSTRAINT order_reviews_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(order_id);"
psql_exec -c "ALTER TABLE orders ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customers(customer_id);"

echo "Data loading completed successfully."
