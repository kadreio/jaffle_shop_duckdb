#!/bin/bash

# Create .bashrc.d directory if it doesn't exist
mkdir -p /home/vscode/.bashrc.d

# Setup dbt bash completion
cp /workspace/dbt-completion.bash /home/vscode/.bashrc.d/
echo 'source /home/vscode/.bashrc.d/dbt-completion.bash' >> /home/vscode/.bashrc

# Configure environment for DuckDB
echo 'export DUCKDB_THREADS=24' >> /home/vscode/.bashrc

# Set up Python virtual environment
VENV_PATH="/home/vscode/.venv"
if [ ! -d "$VENV_PATH" ]; then
  echo "Creating Python virtual environment at $VENV_PATH..."
  python -m venv $VENV_PATH
  echo "Virtual environment created successfully."
fi

# Add venv activation to .bashrc
cat <<EOF >> /home/vscode/.bashrc

# Activate Python virtual environment
if [ -d "$VENV_PATH" ]; then
  source "$VENV_PATH/bin/activate"
fi
EOF

# Activate virtual environment for the current session
source "$VENV_PATH/bin/activate"

# Install/update pip and required packages
echo "Updating pip and installing required packages..."
python -m pip install --upgrade pip
python -m pip install -r /workspace/requirements.txt

# Set up dbt deps
echo "Setting up dbt dependencies..."
dbt deps

# Create utility aliases
cat <<EOF >> /home/vscode/.bashrc
alias dbtrun='dbt run'
alias dbtbuild='dbt build'
alias dbttest='dbt test'
alias dbtdocs='dbt docs generate && dbt docs serve --port 8080'
alias duckbrowse='duckcli jaffle_shop.duckdb'
alias pipupdate='pip install --upgrade -r /workspace/requirements.txt'
EOF

echo "Development environment has been configured successfully!"