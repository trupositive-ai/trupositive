#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
REPO="trupositive-ai/trupositive"

REAL_TF="$(command -v terraform || true)"

if [ -z "$REAL_TF" ]; then
  echo "terraform not found on PATH"
  exit 1
fi

mkdir -p "$BIN_DIR" || {
  echo "Error: Cannot create directory $BIN_DIR" >&2
  exit 1
}

[ -w "$BIN_DIR" ] || {
  echo "Error: Directory $BIN_DIR is not writable" >&2
  exit 1
}

# Remove existing terraform-real if it exists (from previous installation)
if [ -f "$BIN_DIR/terraform-real" ]; then
  rm "$BIN_DIR/terraform-real"
fi

cp "$REAL_TF" "$BIN_DIR/terraform-real" || {
  echo "Error: Failed to copy terraform binary" >&2
  exit 1
}

curl -fsSL "https://raw.githubusercontent.com/trupositive-ai/trupositive/main/terraform" \
  -o "$BIN_DIR/terraform" || {
  echo "Error: Failed to download terraform wrapper" >&2
  exit 1
}

chmod +x "$BIN_DIR/terraform" || {
  echo "Error: Failed to make terraform wrapper executable" >&2
  exit 1
}

curl -fsSL "https://raw.githubusercontent.com/trupositive-ai/trupositive/main/trupositive" \
  -o "$BIN_DIR/trupositive" || {
  echo "Error: Failed to download trupositive CLI" >&2
  exit 1
}

chmod +x "$BIN_DIR/trupositive" || {
  echo "Error: Failed to make trupositive CLI executable" >&2
  exit 1
}

echo "trupositive installed successfully"
echo "Add to PATH: export PATH=\"$BIN_DIR:\$PATH\""
