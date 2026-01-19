#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# trupositive uninstallation script
# Part of trupositive: https://github.com/trupositive-ai/trupositive

set -e
set -o pipefail

BIN_DIR="${TRUPOSITIVE_BIN_DIR:-$HOME/.local/bin}"
TF_WRAPPER="$BIN_DIR/terraform"
REAL_TF="$BIN_DIR/terraform-real"
AWS_WRAPPER="$BIN_DIR/aws"
REAL_AWS="$BIN_DIR/aws-real"
CFN_WRAPPER="$BIN_DIR/cloudformation"
CLI="$BIN_DIR/trupositive"

echo "Uninstalling trupositive..."

# Remove Terraform wrapper
if [ -f "$TF_WRAPPER" ]; then
  rm "$TF_WRAPPER"
  echo "✔ Removed Terraform wrapper: $TF_WRAPPER"
fi

# Restore original Terraform if backup exists
if [ -f "$REAL_TF" ]; then
  echo "Found terraform-real at: $REAL_TF"
  echo "Restoring original terraform binary..."
  
  cp "$REAL_TF" "$BIN_DIR/terraform" || {
    echo "Error: Failed to restore terraform binary" >&2
    exit 1
  }
  
  chmod +x "$BIN_DIR/terraform" || {
    echo "Error: Failed to make terraform executable" >&2
    exit 1
  }
  
  echo "✔ Restored original terraform to: $BIN_DIR/terraform"
  
  rm "$REAL_TF"
  echo "✔ Removed backup: $REAL_TF"
fi

# Remove AWS CLI wrapper
if [ -f "$AWS_WRAPPER" ]; then
  rm "$AWS_WRAPPER"
  echo "✔ Removed AWS wrapper: $AWS_WRAPPER"
fi

# Restore original AWS CLI if backup exists
if [ -f "$REAL_AWS" ]; then
  echo "Found aws-real at: $REAL_AWS"
  echo "Restoring original aws CLI binary..."
  
  cp "$REAL_AWS" "$BIN_DIR/aws" || {
    echo "Error: Failed to restore aws CLI binary" >&2
    exit 1
  }
  
  chmod +x "$BIN_DIR/aws" || {
    echo "Error: Failed to make aws executable" >&2
    exit 1
  }
  
  echo "✔ Restored original aws CLI to: $BIN_DIR/aws"
  
  rm "$REAL_AWS"
  echo "✔ Removed backup: $REAL_AWS"
fi

# Remove CloudFormation wrapper
if [ -f "$CFN_WRAPPER" ]; then
  rm "$CFN_WRAPPER"
  echo "✔ Removed CloudFormation wrapper: $CFN_WRAPPER"
fi

# Remove trupositive CLI
if [ -f "$CLI" ]; then
  rm "$CLI"
  echo "✔ Removed CLI: $CLI"
fi

echo ""
echo "✨ Uninstall complete"
echo ""

