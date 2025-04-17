#!/bin/bash
set -e

echo "===== Initializing development environment for jaffle_shop_duckdb ====="

# Create directories for DuckDB data with proper permissions
echo "Setting up DuckDB data directory..."
mkdir -p /workspaces/jaffle_shop_duckdb/duckdb_data
chmod 777 /workspaces/jaffle_shop_duckdb/duckdb_data

# Set environment variables for DuckDB
echo "Configuring DuckDB environment variables..."
echo 'export DUCKDB_THREADS=24' >> ~/.bashrc
echo 'export DUCKDB_DATABASE_PATH=/workspaces/jaffle_shop_duckdb/duckdb_data/jaffle_shop.duckdb' >> ~/.bashrc

# Copy the container-specific profiles.yml if user doesn't override
if [ ! -f ~/.dbt/profiles.yml ]; then
  echo "Setting up DBT profiles..."
  mkdir -p ~/.dbt
  cp /workspaces/jaffle_shop_duckdb/.devcontainer/profiles.yml ~/.dbt/profiles.yml
fi

# Source the dbt bash completion
if [ -f /workspaces/jaffle_shop_duckdb/dbt-completion.bash ]; then
  echo "Setting up DBT bash completion..."
  echo 'source /workspaces/jaffle_shop_duckdb/dbt-completion.bash' >> ~/.bashrc
fi

# Install development requirements if they exist
if [ -f /workspaces/jaffle_shop_duckdb/requirements-dev.txt ]; then
  echo "Installing development requirements..."
  pip install -r /workspaces/jaffle_shop_duckdb/requirements-dev.txt
fi

# Set up Python virtual environment
VENV_PATH="/home/vscode/.venv"
if [ ! -d "$VENV_PATH" ]; then
  echo "Creating Python virtual environment at $VENV_PATH..."
  python -m venv $VENV_PATH
  
  # Add venv activation to .bashrc
  cat <<EOF >> ~/.bashrc

# Activate Python virtual environment
if [ -d "$VENV_PATH" ]; then
  source "$VENV_PATH/bin/activate"
fi
EOF
fi

# Create utility aliases
echo "Creating helpful aliases..."
cat <<EOF >> ~/.bashrc
alias dbtrun='dbt run'
alias dbtbuild='dbt build'
alias dbttest='dbt test'
alias dbtdocs='dbt docs generate && dbt docs serve --port 8080'
alias duckbrowse='duckcli $DUCKDB_DATABASE_PATH'
alias pipupdate='pip install --upgrade -r /workspaces/jaffle_shop_duckdb/requirements.txt'
EOF

# Initial dbt commands to verify setup
echo "Running initial dbt commands to verify setup..."
dbt --version
echo "Initializing dbt dependencies..."
dbt deps

# Run a simple dbt debug to verify profiles are working
echo "Verifying dbt connection..."
dbt debug

# If TEST_DEVCONTAINER is set, we don't try to run the build yet as that will be handled by the test script
if [ -z "$TEST_DEVCONTAINER" ]; then
  # Load seed data
  echo "Loading seed data..."
  dbt seed
fi

# Install Claude CLI
echo "Installing Claude CLI..."
if npm install -g --unsafe-perm --location=global @anthropic-ai/claude-code 2>/dev/null; then
  echo "Claude CLI installed globally."
else
  echo "Global install failed (permission denied), trying user-local install..."
  if npm install -g --unsafe-perm --prefix ~/.npm-global @anthropic-ai/claude-code; then
    # Ensure ~/.npm-global/bin is on PATH for all shells
    for RC in ~/.bashrc ~/.profile; do
      if ! grep -q 'export PATH="$HOME/.npm-global/bin:$PATH"' "$RC"; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$RC"
      fi
    done
    export PATH="$HOME/.npm-global/bin:$PATH"
    echo "Claude CLI installed to ~/.npm-global/bin."
  else
    echo "WARNING: Failed to install Claude CLI. Please install manually if needed."
  fi
fi

# Print confirmation
echo "===== DuckDB environment configured successfully! ====="
echo "Database location: /workspaces/jaffle_shop_duckdb/duckdb_data/jaffle_shop.duckdb"
echo "Thread configuration: 24 threads"
echo ""
echo "Available aliases:"
echo "  - dbtrun: Run dbt models"
echo "  - dbtbuild: Build dbt models (run + test)"
echo "  - dbttest: Run dbt tests"
echo "  - dbtdocs: Generate and serve dbt documentation"
echo "  - duckbrowse: Open DuckDB CLI"
echo "  - pipupdate: Update Python dependencies"
echo ""
echo "Type 'dbtbuild' to build all models and run tests"
echo "Type 'claude' to use Claude CLI"

# Run test-devcontainer.sh to verify environment if test flag is present
if [ -n "$TEST_DEVCONTAINER" ]; then
  echo "Running devcontainer verification tests..."
  chmod +x /workspaces/jaffle_shop_duckdb/.devcontainer/test-devcontainer.sh
  /workspaces/jaffle_shop_duckdb/.devcontainer/test-devcontainer.sh
fi

echo "To run devcontainer verification tests manually, execute: ./.devcontainer/test-devcontainer.sh"