#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
REPO="trupositive/trupositive"

REAL_TF="$(command -v terraform || true)"

if [ -z "$REAL_TF" ]; then
  echo "terraform not found on PATH"
  exit 1
fi

mkdir -p "$BIN_DIR"

# Backup/update real terraform
# Always update to ensure we're using the latest terraform version
if [ -f "$BIN_DIR/terraform-real" ]; then
  echo "Updating terraform-real to latest version..."
fi
cp "$REAL_TF" "$BIN_DIR/terraform-real"

# Install terraform wrapper
curl -fsSL "https://raw.githubusercontent.com/trupositive/trupositive/main/terraform" \
  -o "$BIN_DIR/terraform"

chmod +x "$BIN_DIR/terraform"

# Install trupositive CLI
curl -fsSL "https://raw.githubusercontent.com/trupositive/trupositive/main/trupositive" \
  -o "$BIN_DIR/trupositive"

chmod +x "$BIN_DIR/trupositive"

echo ""
echo "trupositive installed successfully"
echo "Make sure $BIN_DIR is before terraform in PATH:"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
