#!/usr/bin/env bash
set -e

BIN_DIR="${HOME}/.local/bin"
WRAPPER="$BIN_DIR/terraform"
REAL_TF="$BIN_DIR/terraform-real"
CLI="$BIN_DIR/trupositive"

if [ -f "$WRAPPER" ]; then
  rm "$WRAPPER"
  echo "Removed wrapper: $WRAPPER"
fi

if [ -f "$CLI" ]; then
  rm "$CLI"
  echo "Removed CLI: $CLI"
fi

if [ -f "$REAL_TF" ]; then
  echo "Found terraform-real at: $REAL_TF"
  echo "Restoring original terraform binary..."
  
  # Restore terraform-real as terraform in ~/.local/bin
  cp "$REAL_TF" "$BIN_DIR/terraform" || {
    echo "Error: Failed to restore terraform binary" >&2
    exit 1
  }
  
  chmod +x "$BIN_DIR/terraform" || {
    echo "Error: Failed to make terraform executable" >&2
    exit 1
  }
  
  echo "✅ Restored original terraform to: $BIN_DIR/terraform"
  
  # Remove terraform-real backup
  rm "$REAL_TF"
  echo "Removed backup: $REAL_TF"
fi

echo "Uninstall complete"

