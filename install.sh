#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# trupositive installation script
# Part of trupositive: https://github.com/trupositive-ai/trupositive

set -e
set -o pipefail

BIN_DIR="${TRUPOSITIVE_BIN_DIR:-$HOME/.local/bin}"
REPO="trupositive-ai/trupositive"

# Find binaries with validation
REAL_TF=""
REAL_AWS=""

if command -v terraform >/dev/null 2>&1; then
  REAL_TF=$(command -v terraform)
  # Validate it's executable
  if [ ! -x "$REAL_TF" ]; then
    echo "Warning: terraform found but not executable: $REAL_TF" >&2
    REAL_TF=""
  fi
fi

if command -v aws >/dev/null 2>&1; then
  REAL_AWS=$(command -v aws)
  # Validate it's executable
  if [ ! -x "$REAL_AWS" ]; then
    echo "Warning: aws found but not executable: $REAL_AWS" >&2
    REAL_AWS=""
  fi
fi

if [ -z "$REAL_TF" ] && [ -z "$REAL_AWS" ]; then
  echo "Error: Neither terraform nor aws CLI found on PATH" >&2
  echo "Please install at least one of: Terraform or AWS CLI" >&2
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

# Install Terraform wrapper if terraform is available
if [ -n "$REAL_TF" ]; then
  echo "Installing Terraform wrapper..."
  
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
  
  echo "✔ Terraform wrapper installed"
fi

# Install CloudFormation wrapper if AWS CLI is available
if [ -n "$REAL_AWS" ]; then
  echo "Installing CloudFormation wrapper..."
  
  # Remove existing aws-real if it exists (from previous installation)
  if [ -f "$BIN_DIR/aws-real" ]; then
    rm "$BIN_DIR/aws-real"
  fi

  cp "$REAL_AWS" "$BIN_DIR/aws-real" || {
    echo "Error: Failed to copy aws CLI binary" >&2
    exit 1
  }

  curl -fsSL "https://raw.githubusercontent.com/trupositive-ai/trupositive/main/cloudformation" \
    -o "$BIN_DIR/cloudformation" || {
    echo "Error: Failed to download cloudformation wrapper" >&2
    exit 1
  }

  chmod +x "$BIN_DIR/cloudformation" || {
    echo "Error: Failed to make cloudformation wrapper executable" >&2
    exit 1
  }
  
  # Also create aws wrapper that uses aws-real
  # Use variable expansion to avoid hardcoding paths
  cat > "$BIN_DIR/aws" <<EOFAWS
#!/bin/bash
# SPDX-License-Identifier: MIT
# AWS CLI wrapper for trupositive CloudFormation integration
set -e

# Determine wrapper location dynamically
WRAPPER_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
AWS_REAL="\$WRAPPER_DIR/aws-real"
CFN_WRAPPER="\$WRAPPER_DIR/cloudformation"

# Validate binaries exist and are executable
if [ ! -x "\$AWS_REAL" ]; then
  echo "Error: aws-real not found or not executable at \$AWS_REAL" >&2
  exit 1
fi

# If this is a cloudformation command, use the cloudformation wrapper
if [ "\$1" = "cloudformation" ]; then
  if [ ! -x "\$CFN_WRAPPER" ]; then
    echo "Error: cloudformation wrapper not found at \$CFN_WRAPPER" >&2
    exit 1
  fi
  exec "\$CFN_WRAPPER" "\$@"
fi

# Otherwise, pass through to real AWS CLI
exec "\$AWS_REAL" "\$@"
EOFAWS
  
  chmod +x "$BIN_DIR/aws" || {
    echo "Error: Failed to make aws wrapper executable" >&2
    exit 1
  }
  
  echo "✔ CloudFormation wrapper installed"
fi

curl -fsSL "https://raw.githubusercontent.com/trupositive-ai/trupositive/main/trupositive" \
  -o "$BIN_DIR/trupositive" || {
  echo "Error: Failed to download trupositive CLI" >&2
  exit 1
}

chmod +x "$BIN_DIR/trupositive" || {
  echo "Error: Failed to make trupositive CLI executable" >&2
  exit 1
}

echo ""
echo "✨ trupositive installed successfully"
if [ -n "$REAL_TF" ]; then
  echo "   ✔ Terraform wrapper enabled"
fi
if [ -n "$REAL_AWS" ]; then
  echo "   ✔ CloudFormation wrapper enabled"
fi
echo ""
echo "📝 Add to PATH: export PATH=\"$BIN_DIR:\$PATH\""
echo ""
