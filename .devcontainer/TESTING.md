# Testing the Dev Container

This document outlines how to verify that your dev container is properly configured for the jaffle_shop_duckdb project.

## Testing with Devcontainer CLI

The most comprehensive way to test the devcontainer is to use the devcontainer CLI, which allows you to build and test the container from the command line without VS Code:

1. Install the devcontainer CLI:
   ```bash
   npm install -g @devcontainers/cli
   ```

2. Run the automated build and test script:
   ```bash
   ./.devcontainer/test-build.sh
   ```

This script will:
- Build the devcontainer from scratch
- Start the container
- Run the test script inside the container
- Verify dbt functionality

This approach is ideal for CI/CD environments or when you want to ensure the container builds correctly from a clean state.

## Continuous Integration Testing

A GitHub Actions workflow is configured to automatically test the devcontainer whenever changes are made to:
- `.devcontainer/**` files
- `Dockerfile`
- `requirements.txt`

The workflow can be found in `.github/workflows/test-devcontainer.yml` and performs the same sequence of tests as the test-build.sh script.

## Automated Testing

When the container is first created, it will automatically run a verification test script if the `TEST_DEVCONTAINER` environment variable is set to "true" (default in devcontainer.json).

You can also run the test script manually at any time:

```bash
./.devcontainer/test-devcontainer.sh
```

This script verifies:
- Environment variables are set correctly
- Required tools are installed
- Directory structure is as expected
- dbt functionality works properly
- Data persistence is configured

## Manual Testing Checklist

In addition to the automated tests, you should perform these manual checks:

### 1. Verify Environment Setup

- [ ] Confirm Python virtual environment is activated (you should see a `(.venv)` prefix in your terminal)
- [ ] Check that all dbt aliases work:
  ```bash
  dbtrun --help
  dbtbuild --help 
  dbttest --help
  dbtdocs --help
  ```

### 2. Test dbt Functionality

- [ ] Run full dbt build
  ```bash
  dbt build
  ```
- [ ] Generate and serve docs
  ```bash
  dbtdocs
  ```
  Verify you can access docs in your browser at http://localhost:8080

### 3. Test DuckDB Connectivity

- [ ] Verify duckcli works
  ```bash
  duckbrowse
  ```
  In the duckcli prompt, try:
  ```
  .tables
  SELECT * FROM stg_customers LIMIT 5;
  ```

### 4. Test VS Code Integration

- [ ] Verify SQL linting works by creating a test SQL file with deliberate errors
- [ ] Verify dbt intellisense works by referencing models in a new query
- [ ] Try running VS Code tasks from Command Palette:
  - "Tasks: Run Build Task" (should run dbt build)
  - "Tasks: Run Test Task" (should run dbt test)

### 5. Test Data Persistence

- [ ] Create a new table in DuckDB:
  ```sql
  CREATE TABLE test_persistence AS SELECT 1 AS id, 'test' AS value;
  ```
- [ ] Restart the container (you can use Developer: Rebuild Container from VS Code)
- [ ] Verify table still exists:
  ```bash
  duckbrowse
  ```
  ```sql
  SELECT * FROM test_persistence;
  ```

## Troubleshooting

If any tests fail, check:

1. Container environment variables in `.devcontainer/devcontainer.json`
2. Post-create script in `.devcontainer/post-create.sh`
3. DuckDB configuration in `.devcontainer/profiles.yml`
4. Volume mounts in `.devcontainer/devcontainer.json`