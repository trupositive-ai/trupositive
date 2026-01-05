#!/usr/bin/env bash
set -e

BIN_DIR="${HOME}/.local/bin"
WRAPPER="$BIN_DIR/terraform"
REAL_TF="$BIN_DIR/terraform-real"

if [ -f "$WRAPPER" ]; then
  rm "$WRAPPER"
  echo "Removed wrapper: $WRAPPER"
fi

if [ -f "$REAL_TF" ]; then
  echo "Found terraform-real at: $REAL_TF"
  read -p "Do you want to restore it to the original location? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ORIGINAL_LOCATION=$(which terraform-real 2>/dev/null || echo "/usr/local/bin/terraform")
    echo "Restoring terraform-real to: $ORIGINAL_LOCATION"
    
    # Check if sudo is available
    if ! command -v sudo >/dev/null 2>&1; then
      echo "❌ Error: sudo is not available. Cannot restore terraform to system location." >&2
      echo "   You can manually copy $REAL_TF to your desired location." >&2
      exit 1
    fi
    
    # Check if destination directory is writable (or will be with sudo)
    DEST_DIR=$(dirname "$ORIGINAL_LOCATION")
    if [ ! -w "$DEST_DIR" ] && ! sudo -n test -w "$DEST_DIR" 2>/dev/null; then
      echo "⚠️  Warning: Destination directory $DEST_DIR may not be writable"
    fi
    
    # Attempt to copy with error checking
    if sudo cp "$REAL_TF" "$ORIGINAL_LOCATION" 2>/dev/null; then
      # Verify the copy succeeded
      if [ -f "$ORIGINAL_LOCATION" ]; then
        echo "✅ Restored terraform to: $ORIGINAL_LOCATION"
      else
        echo "❌ Error: Copy appeared to succeed but file not found at destination" >&2
        exit 1
      fi
    else
      echo "❌ Error: Failed to restore terraform. sudo may have failed or destination is not writable." >&2
      echo "   Source: $REAL_TF" >&2
      echo "   Destination: $ORIGINAL_LOCATION" >&2
      exit 1
    fi
  else
    echo "Keeping terraform-real at: $REAL_TF"
  fi
fi

echo "Uninstall complete"

