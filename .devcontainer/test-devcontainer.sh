#!/bin/bash
# Test script for verifying the devcontainer setup
set -e

echo "=== DEVCONTAINER TEST SCRIPT ==="
echo "Testing jaffle_shop_duckdb devcontainer configuration"
echo

# Function to report test status
test_status() {
    if [ $? -eq 0 ]; then
        echo "✅ PASSED: $1"
    else
        echo "❌ FAILED: $1"
        failed_tests+=("$1")
    fi
}

# Store failed tests
failed_tests=()

echo "=== Testing environment variables ==="
echo "DUCKDB_THREADS: ${DUCKDB_THREADS}"
echo "DUCKDB_DATABASE_PATH: ${DUCKDB_DATABASE_PATH}"
[ -n "${DUCKDB_THREADS}" ] && [ "${DUCKDB_THREADS}" = "24" ]
test_status "DUCKDB_THREADS environment variable is correctly set"
[ -n "${DUCKDB_DATABASE_PATH}" ] && [[ "${DUCKDB_DATABASE_PATH}" == */workspace/duckdb_data/jaffle_shop.duckdb ]]
test_status "DUCKDB_DATABASE_PATH environment variable is correctly set"

echo
echo "=== Testing installed tools ==="
# Check Python
python --version
test_status "Python is installed"

# Check pip
pip --version
test_status "pip is installed"

# Check dbt
dbt --version
test_status "dbt is installed"

# Check duckcli
which duckcli >/dev/null
test_status "duckcli is installed"

# Check sqlfluff
which sqlfluff >/dev/null
test_status "sqlfluff is installed"

echo
echo "=== Testing directory structure ==="
# Test data directory
[ -d "/workspace/duckdb_data" ]
test_status "DuckDB data directory exists"

# Test dbt profiles
[ -f "${HOME}/.dbt/profiles.yml" ]
test_status "dbt profiles.yml exists"

echo
echo "=== Testing dbt functionality ==="
# Test dbt debug
dbt debug --target dev
test_status "dbt debug runs successfully"

# First seed the data
echo "Running dbt seed to load initial data..."
dbt seed --target dev
test_status "dbt seed runs successfully"

# Then test dbt build (with limited scope for quick testing)
echo "Running dbt build on a subset of models..."
dbt build --select staging.stg_customers --target dev
test_status "dbt build runs successfully"

# Test docs generation
echo "Generating dbt docs..."
dbt docs generate --target dev
test_status "dbt docs generation works"

echo
echo "=== Testing data persistence ==="
# Test database file creation
[ -f "${DUCKDB_DATABASE_PATH}" ] || [ -f "jaffle_shop.duckdb" ]
test_status "DuckDB database file was created"

# Test DuckDB connectivity and data persistence
echo "Testing DuckDB connection with duckcli..."
if [ -f "${DUCKDB_DATABASE_PATH}" ]; then
  # Ensure proper permissions
  chmod 666 "${DUCKDB_DATABASE_PATH}"
  DB_PATH="${DUCKDB_DATABASE_PATH}"
else
  DB_PATH="jaffle_shop.duckdb"
fi

# Check tables
TABLES=$(echo ".tables" | duckcli "${DB_PATH}" -t)
echo "${TABLES}"
echo "${TABLES}" | grep -q "raw_customers"
test_status "duckcli can connect to the database and find tables"

# Test data persistence by creating a test table
echo "Testing data persistence..."
echo "CREATE TABLE IF NOT EXISTS test_persistence (id INTEGER, value TEXT);" | duckcli "${DB_PATH}"
echo "INSERT INTO test_persistence VALUES (1, 'test');" | duckcli "${DB_PATH}"
echo "SELECT * FROM test_persistence;" | duckcli "${DB_PATH}" -t | grep -q "test"
test_status "Can create and query tables in DuckDB"

# Report summary
echo
echo "=== TEST SUMMARY ==="
if [ ${#failed_tests[@]} -eq 0 ]; then
    echo "🎉 All tests passed successfully!"
else
    echo "😞 ${#failed_tests[@]} tests failed:"
    for test in "${failed_tests[@]}"; do
        echo "   - $test"
    done
    exit 1
fi

# Test clean-up
echo
echo "Test complete. The devcontainer is functioning correctly."