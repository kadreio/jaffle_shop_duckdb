#!/bin/bash
# Test script to verify the devcontainer builds and functions properly using the devcontainer CLI
set -e

echo "=== DEVCONTAINER BUILD & TEST SCRIPT ==="
echo "This script requires the devcontainer CLI to be installed."
echo "Installation: npm install -g @devcontainers/cli"
echo

# Check if devcontainer CLI is installed
if ! command -v devcontainer &> /dev/null; then
    echo "❌ ERROR: devcontainer CLI not found. Please install it with:"
    echo "npm install -g @devcontainers/cli"
    exit 1
fi

# Get the repo root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Repository root: $REPO_ROOT"

# Build the dev container
echo "=== Building the dev container ==="
cd "$REPO_ROOT"
devcontainer build --workspace-folder .

# Test: Run the container and execute test script
echo
echo "=== Testing the dev container ==="
devcontainer up --workspace-folder .

# Run the test script inside the container
echo
echo "=== Running tests inside the container ==="
devcontainer exec --workspace-folder . bash -c "cd /workspaces/jaffle_shop_duckdb && export TEST_DEVCONTAINER=true && ./.devcontainer/test-devcontainer.sh"

# Additional: Test dbt commands
echo
echo "=== Testing dbt commands ==="
devcontainer exec --workspace-folder . bash -c "cd /workspaces/jaffle_shop_duckdb && dbt --version"
devcontainer exec --workspace-folder . bash -c "cd /workspaces/jaffle_shop_duckdb && dbt debug"

echo
echo "=== All tests completed successfully! ==="
echo "The devcontainer has been built, started, and tested successfully."
echo "You can now use it for development."