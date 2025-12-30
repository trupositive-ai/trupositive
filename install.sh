#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
REPO="simmestdagh/tf-git"

REAL_TF="$(command -v terraform || true)"

if [ -z "$REAL_TF" ]; then
  echo "terraform not found on PATH"
  exit 1
fi

mkdir -p "$BIN_DIR"

# Backup real terraform once
if [ ! -f "$BIN_DIR/terraform-real" ]; then
  cp "$REAL_TF" "$BIN_DIR/terraform-real"
fi

# Install wrapper
curl -fsSL "https://raw.githubusercontent.com/$REPO/main/terraform" \
  -o "$BIN_DIR/terraform"

chmod +x "$BIN_DIR/terraform"

echo ""
echo "tf-git installed successfully"
echo "Make sure $BIN_DIR is before terraform in PATH:"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
