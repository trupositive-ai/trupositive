#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# trupositive installation script
# Part of trupositive: https://github.com/trupositive-ai/trupositive

set -e
set -o pipefail

BIN_DIR="${TRUPOSITIVE_BIN_DIR:-$HOME/.local/bin}"

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

  cat > "$BIN_DIR/terraform" <<'EOFTF'
#!/bin/bash
# SPDX-License-Identifier: MIT
# Terraform wrapper that automatically injects Git metadata as variables
# Part of trupositive: https://github.com/trupositive-ai/trupositive

set -e
set -o pipefail

# Extract Git metadata with safe defaults
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Try to get branch name with better CI/detached HEAD handling
GIT_BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null || \
  git rev-parse --abbrev-ref HEAD 2>/dev/null || \
  echo "${GITHUB_REF_NAME:-${CI_COMMIT_REF_NAME:-${BUILD_SOURCEBRANCHNAME:-${BRANCH_NAME:-unknown}}}}")

# Security: Sanitize branch name and limit length
# Remove any characters that could break Terraform variable assignment
GIT_BRANCH=$(echo "$GIT_BRANCH" | sed 's/[^a-zA-Z0-9\/.\-_]//g' | head -c 200)
[ -z "$GIT_BRANCH" ] && GIT_BRANCH="unknown"

GIT_REPO=$(git config --get remote.origin.url 2>/dev/null || echo "unknown")

# Sanitize Git repo URL to prevent injection
# Keep only alphanumeric, :, /, ., -, _, and @
# Also limit length to prevent extremely long URLs
GIT_REPO_SANITIZED=$(echo "$GIT_REPO" | sed 's/[^a-zA-Z0-9:\/.\-_@]//g' | head -c 1000)
[ -z "$GIT_REPO_SANITIZED" ] && GIT_REPO_SANITIZED="unknown"

# Export as Terraform variables
export TF_VAR_git_sha="$GIT_SHA"
export TF_VAR_git_branch="$GIT_BRANCH"
export TF_VAR_git_repo="$GIT_REPO_SANITIZED"

# Find terraform binary dynamically
# Priority: terraform-real (from installation) > system terraform
find_terraform_binary() {
  local tf_bin=""
  
  if [ -f "$HOME/.local/bin/terraform-real" ]; then
    tf_bin="$HOME/.local/bin/terraform-real"
  elif command -v terraform-real >/dev/null 2>&1; then
    tf_bin=$(command -v terraform-real)
  elif command -v terraform >/dev/null 2>&1; then
    tf_bin=$(command -v terraform)
  else
    echo "Error: terraform binary not found. Please install Terraform." >&2
    exit 1
  fi
  
  # Validate the binary is executable
  if [ ! -x "$tf_bin" ]; then
    echo "Error: terraform binary is not executable: $tf_bin" >&2
    exit 1
  fi
  
  echo "$tf_bin"
}

TERRAFORM_BIN=$(find_terraform_binary)

# Pass through all arguments to terraform
exec "$TERRAFORM_BIN" "$@"
EOFTF

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

  cat > "$BIN_DIR/cloudformation" <<'EOFCFN'
#!/bin/bash
# SPDX-License-Identifier: MIT
# CloudFormation wrapper that automatically injects Git metadata as parameters
# Part of trupositive: https://github.com/trupositive-ai/trupositive

set -e
set -o pipefail

# Extract Git metadata with safe defaults
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Try to get branch name with better CI/detached HEAD handling
GIT_BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null || \
  git rev-parse --abbrev-ref HEAD 2>/dev/null || \
  echo "${GITHUB_REF_NAME:-${CI_COMMIT_REF_NAME:-${BUILD_SOURCEBRANCHNAME:-${BRANCH_NAME:-unknown}}}}")

# Security: Sanitize branch name and limit length
# Remove any characters that could break CloudFormation parameter syntax
GIT_BRANCH=$(echo "$GIT_BRANCH" | sed 's/[^a-zA-Z0-9\/.\-_]//g' | head -c 200)
[ -z "$GIT_BRANCH" ] && GIT_BRANCH="unknown"

GIT_REPO=$(git config --get remote.origin.url 2>/dev/null || echo "unknown")

# Sanitize Git repo URL to prevent injection
# Keep only alphanumeric, :, /, ., -, _, and @
# Also limit length to prevent extremely long URLs
GIT_REPO_SANITIZED=$(echo "$GIT_REPO" | sed 's/[^a-zA-Z0-9:\/.\-_@]//g' | head -c 1000)
[ -z "$GIT_REPO_SANITIZED" ] && GIT_REPO_SANITIZED="unknown"

# Find AWS CLI binary dynamically
# Priority: aws-real (from installation) > system aws
find_aws_binary() {
  local aws_bin=""
  
  if [ -f "$HOME/.local/bin/aws-real" ]; then
    aws_bin="$HOME/.local/bin/aws-real"
  elif command -v aws-real >/dev/null 2>&1; then
    aws_bin=$(command -v aws-real)
  elif command -v aws >/dev/null 2>&1; then
    aws_bin=$(command -v aws)
  else
    echo "Error: aws CLI binary not found. Please install AWS CLI." >&2
    exit 1
  fi
  
  # Validate the binary is executable
  if [ ! -x "$aws_bin" ]; then
    echo "Error: aws CLI binary is not executable: $aws_bin" >&2
    exit 1
  fi
  
  echo "$aws_bin"
}

AWS_BIN=$(find_aws_binary)

# Validate we have at least one argument
if [ $# -eq 0 ]; then
  exec "$AWS_BIN"
fi

# Handle both calling patterns:
# 1. From trupositive CLI: cloudformation deploy ...
# 2. From aws wrapper: cloudformation cloudformation deploy ...
# Strip "cloudformation" keyword if present as first argument
if [ "$1" = "cloudformation" ]; then
  shift
fi

# After stripping, check if this is a CloudFormation command
# Detect if this command accepts parameters
command_accepts_parameters() {
  local cmd=""
  for arg in "$@"; do
    # Skip flags to find the actual command
    if [[ ! "$arg" =~ ^-- ]]; then
      cmd="$arg"
      break
    fi
  done
  
  case "$cmd" in
    deploy|create-stack|update-stack|create-change-set)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Check if this looks like a CloudFormation command
is_cloudformation_command() {
  local cmd=""
  for arg in "$@"; do
    if [[ ! "$arg" =~ ^-- ]]; then
      cmd="$arg"
      break
    fi
  done
  
  case "$cmd" in
    deploy|create-stack|update-stack|delete-stack|describe-stacks|list-stacks|create-change-set|execute-change-set|describe-change-set)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# If not a CloudFormation command, pass through to AWS CLI
if ! is_cloudformation_command "$@"; then
  exec "$AWS_BIN" "$@"
fi

# Parse arguments to inject Git parameters
NEW_ARGS=()
INJECT_PARAMS=true
PARAM_OVERRIDE_ADDED=false
PARAM_FILE_MODE=false

for arg in "$@"; do
  # Check if --parameter-overrides already exists
  if [ "$arg" = "--parameter-overrides" ]; then
    PARAM_OVERRIDE_ADDED=true
    NEW_ARGS+=("$arg")
    # Add our Git parameters right after --parameter-overrides
    NEW_ARGS+=("GitSha=$GIT_SHA")
    NEW_ARGS+=("GitBranch=$GIT_BRANCH")
    NEW_ARGS+=("GitRepo=$GIT_REPO_SANITIZED")
  # Check if --parameters is used (file-based parameters)
  elif [ "$arg" = "--parameters" ]; then
    PARAM_FILE_MODE=true
    NEW_ARGS+=("$arg")
  # Check if user explicitly disabled our injection (custom flag)
  elif [ "$arg" = "--no-git-params" ]; then
    INJECT_PARAMS=false
  else
    NEW_ARGS+=("$arg")
  fi
done

# If --parameter-overrides wasn't provided and injection is enabled,
# add it for commands that accept parameters
if [ "$INJECT_PARAMS" = "true" ] && \
   [ "$PARAM_OVERRIDE_ADDED" = "false" ] && \
   [ "$PARAM_FILE_MODE" = "false" ]; then
  if command_accepts_parameters "$@"; then
    NEW_ARGS+=("--parameter-overrides")
    NEW_ARGS+=("GitSha=$GIT_SHA")
    NEW_ARGS+=("GitBranch=$GIT_BRANCH")
    NEW_ARGS+=("GitRepo=$GIT_REPO_SANITIZED")
  fi
fi

# Pass through all arguments to AWS CLI with "cloudformation" prefix
exec "$AWS_BIN" cloudformation "${NEW_ARGS[@]}"
EOFCFN

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

cat > "$BIN_DIR/trupositive" <<'EOFTP'
#!/bin/bash
# SPDX-License-Identifier: MIT
# trupositive CLI - handles init command and passes through to terraform/cloudformation wrapper
# Part of trupositive: https://github.com/trupositive-ai/trupositive

set -e
set -o pipefail

# Detect infrastructure tool (terraform or cloudformation)
INFRA_TOOL=""

# Check if a file is a CloudFormation template
is_cloudformation_template() {
  local file="$1"
  [ -f "$file" ] || return 1
  
  # CloudFormation templates must have AWSTemplateFormatVersion or be SAM templates
  # More strict matching to avoid false positives from comments/strings
  if grep -q "^AWSTemplateFormatVersion:" "$file" 2>/dev/null || \
     grep -q "^Transform:.*AWS::Serverless" "$file" 2>/dev/null; then
    return 0
  fi
  
  # For JSON files, check for both AWSTemplateFormatVersion and Resources at root level
  if [[ "$file" == *.json ]]; then
    if grep -q '"AWSTemplateFormatVersion"' "$file" 2>/dev/null && \
       grep -q '"Resources"' "$file" 2>/dev/null; then
      return 0
    fi
  fi
  
  return 1
}

detect_infra_tool() {
  local has_yaml=false
  local has_yml=false
  local has_json=false
  local has_tf=false
  
  # Check what file types exist to avoid unnecessary globbing
  # Use find with maxdepth to safely check for files
  [ "$(find . -maxdepth 1 -name '*.yaml' -type f 2>/dev/null | head -n 1)" ] && has_yaml=true
  [ "$(find . -maxdepth 1 -name '*.yml' -type f 2>/dev/null | head -n 1)" ] && has_yml=true
  [ "$(find . -maxdepth 1 -name '*.json' -type f 2>/dev/null | head -n 1)" ] && has_json=true
  [ "$(find . -maxdepth 1 -name '*.tf' -type f 2>/dev/null | head -n 1)" ] && has_tf=true
  
  # Check for CloudFormation templates
  if [ "$has_yaml" = "true" ] || [ "$has_yml" = "true" ] || [ "$has_json" = "true" ]; then
    # Use nullglob to handle case where no files match
    shopt -s nullglob
    for file in *.yaml *.yml *.json; do
      # Ensure file exists and is a regular file
      [ -f "$file" ] || continue
      
      # Security: Ensure file is in current directory (no path traversal)
      if [[ "$file" == *"/"* ]] || [[ "$file" == *".."* ]]; then
        continue
      fi
      
      if is_cloudformation_template "$file"; then
        INFRA_TOOL="cloudformation"
        shopt -u nullglob
        return 0
      fi
    done
    shopt -u nullglob
  fi
  
  # Check for Terraform files
  if [ "$has_tf" = "true" ]; then
    INFRA_TOOL="terraform"
    return 0
  fi
  
  return 1
}

# ======================================
# CloudFormation Functions
# ======================================

# Function to generate CloudFormation parameters template
run_init_cloudformation() {
  local filename="trupositive-params.yaml"
  
  # Security: Ensure filename doesn't contain path separators
  if [[ "$filename" == *"/"* ]] || [[ "$filename" == *".."* ]]; then
    echo "❌ Error: Invalid filename" >&2
    return 1
  fi
  
  # Check if file already exists
  if [ -f "$filename" ]; then
    echo "⚠️  trupositive-params.yaml already exists — aborting to avoid overwrite"
    echo "   Delete the file first if you want to regenerate it"
    return 1
  fi
  
  # Validate we're in a directory with CloudFormation templates
  local has_cfn_template=false
  for file in *.yaml *.yml *.json; do
    [ -f "$file" ] || continue
    if grep -q "AWSTemplateFormatVersion\|Resources:" "$file" 2>/dev/null; then
      has_cfn_template=true
      break
    fi
  done
  
  if [ "$has_cfn_template" = false ]; then
    echo "❌ Error: No CloudFormation templates found in current directory" >&2
    echo "   Please run 'trupositive init' from a CloudFormation project directory" >&2
    return 1
  fi
  
  # Check write permissions
  if [ ! -w . ]; then
    echo "❌ Error: No write permission in current directory" >&2
    return 1
  fi
  
  # Generate parameter template file
  cat > "$filename" <<'INNEREOF'
# ===============================================
# trupositive generated file
# ===============================================
# This file was generated by 'trupositive init'
# It provides parameter definitions for Git metadata in CloudFormation.
# ===============================================
#
# Add these parameters to your CloudFormation template:
#
Parameters:
  GitSha:
    Type: String
    Default: "unknown"
    Description: Git commit SHA
  
  GitBranch:
    Type: String
    Default: "unknown"
    Description: Git branch name
  
  GitRepo:
    Type: String
    Default: "unknown"
    Description: Git repository URL

# ===============================================
# Usage Examples
# ===============================================
#
# Add these tags to your resources:
#
# Example 1: EC2 Instance
# Resources:
#   MyInstance:
#     Type: AWS::EC2::Instance
#     Properties:
#       # ... other properties ...
#       Tags:
#         - Key: git_sha
#           Value: !Ref GitSha
#         - Key: git_branch
#           Value: !Ref GitBranch
#         - Key: git_repo
#           Value: !Ref GitRepo
#
# Example 2: S3 Bucket
# Resources:
#   MyBucket:
#     Type: AWS::S3::Bucket
#     Properties:
#       # ... other properties ...
#       Tags:
#         - Key: git_sha
#           Value: !Ref GitSha
#         - Key: git_branch
#           Value: !Ref GitBranch
#         - Key: git_repo
#           Value: !Ref GitRepo
#
# ===============================================
# Deployment
# ===============================================
#
# The cloudformation wrapper automatically injects these parameters:
#
#   aws cloudformation deploy \
#     --template-file template.yaml \
#     --stack-name my-stack
#
# Or explicitly with parameter overrides:
#
#   aws cloudformation deploy \
#     --template-file template.yaml \
#     --stack-name my-stack \
#     --parameter-overrides GitSha=abc123 GitBranch=main GitRepo=myrepo
#
INNEREOF
  
  echo ""
  echo "✨ Created trupositive-params.yaml"
  echo "✔  Parameter definitions and examples provided"
  echo ""
  echo "📝 Next steps:"
  echo "   1. Copy the Parameters section to your CloudFormation template(s)"
  echo "   2. Add Git metadata tags to your resources (see examples in the file)"
  echo "   3. Use 'aws cloudformation deploy' - Git parameters are injected automatically"
  echo ""
  echo "💡 Tip: The cloudformation wrapper automatically passes Git metadata as parameters"
  echo ""
}

# ======================================
# Terraform Functions
# ======================================

# Function to detect existing provider blocks
# Uses more precise pattern matching to avoid false positives from comments/strings
detect_existing_provider() {
  local provider="$1"
  local provider_file=""
  local provider_line=""
  
  # Security: Validate provider input
  case "$provider" in
    aws|google|azurerm)
      # Valid provider
      ;;
    *)
      return 1
      ;;
  esac
  
  # Search for existing provider blocks
  # Pattern: provider "provider_name" { (not in comments or strings)
  for file in *.tf; do
    [ -f "$file" ] || continue
    
    # Security: Ensure file is in current directory (no path traversal)
    if [[ "$file" == *"/"* ]] || [[ "$file" == *".."* ]]; then
      continue  # Skip suspicious filenames
    fi
    if [ "$(dirname "$file")" != "." ]; then
      continue  # Skip files not in current directory
    fi
    
    # Use awk to find provider blocks, skipping comments and strings
    # Look for: provider "provider_name" { on a line (possibly with whitespace)
    result="$(awk '
      /^[[:space:]]*provider[[:space:]]+"'"$provider"'"[[:space:]]*\{/ {
        if (!/^[[:space:]]*#/) {  # Not a comment
          print FILENAME":"NR
          exit 0
        }
      }
    ' "$file" 2>/dev/null | head -1)"
    if [ -n "$result" ]; then
      provider_file=$(echo "$result" | cut -d: -f1)
      provider_line=$(echo "$result" | cut -d: -f2)
      
      # Security: Validate extracted filename
      if [[ "$provider_file" == *"/"* ]] || [[ "$provider_file" == *".."* ]]; then
        continue  # Skip suspicious filenames
      fi
      if [ "$(dirname "$provider_file")" != "." ]; then
        continue  # Skip files not in current directory
      fi
      
      echo "$provider_file:$provider_line"
      return 0
    fi
  done
  
  return 1
}

# Function to generate provider patch
generate_provider_patch() {
  local provider="$1"
  local provider_file="$2"
  local provider_line="$3"
  
  case "$provider" in
    aws)
      cat <<PATCHEOF

# Add this default_tags block to your existing provider "aws" block:
  default_tags {
    tags = {
      git_sha    = var.git_sha
      git_branch = var.git_branch
      git_repo   = var.git_repo
    }
  }
PATCHEOF
      ;;
    azurerm)
      cat <<PATCHEOF

# Azure doesn't support provider-level default_tags like AWS.
# The locals block has been automatically added to trupositive.auto.tf.
# Now add tags to each resource:
#   tags = local.default_tags
#
# Example:
# resource "azurerm_storage_account" "example" {
#   name     = "example"
#   ...
#   tags = local.default_tags
# }
PATCHEOF
      ;;
    google)
      cat <<PATCHEOF

# GCP uses labels instead of tags, and provider-wide defaults aren't uniform.
# The locals block has been automatically added to trupositive.auto.tf.
# Now add labels to each resource:
#   labels = local.default_labels
#
# Example:
# resource "google_storage_bucket" "example" {
#   name     = "example"
#   ...
#   labels = local.default_labels
# }
#
# See: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#labels
PATCHEOF
      ;;
  esac
}

# Function to generate trupositive.auto.tf
run_init() {
  # Security: Hardcode filename to prevent path traversal
  local filename="trupositive.auto.tf"
  
  # Security: Ensure filename doesn't contain path separators
  if [[ "$filename" == *"/"* ]] || [[ "$filename" == *".."* ]]; then
    echo "❌ Error: Invalid filename" >&2
    return 1
  fi
  
  # Check if file already exists
  if [ -f "$filename" ]; then
    echo "⚠️  trupositive.auto.tf already exists — aborting to avoid overwrite"
    echo "   Delete the file first if you want to regenerate it"
    return 1
  fi
  
  # Validate we're in a directory with .tf files
  if ! ls *.tf >/dev/null 2>&1; then
    echo "❌ Error: No .tf files found in current directory" >&2
    echo "   Please run 'trupositive init' from a Terraform project directory" >&2
    return 1
  fi
  
  # Check write permissions
  if [ ! -w . ]; then
    echo "❌ Error: No write permission in current directory" >&2
    return 1
  fi
  
  # Detect provider by checking existing .tf files
  # Use more precise pattern matching to avoid false positives from comments/strings
  local provider="azurerm"
  local provider_found=false
  
  # Security: Validate we're only processing files in current directory
  # Prevent path traversal by ensuring no subdirectories
  for file in *.tf; do
    [ -f "$file" ] || continue
    # Security: Ensure file is in current directory (no path separators)
    if [[ "$file" == *"/"* ]] || [[ "$file" == *".."* ]]; then
      continue  # Skip suspicious filenames
    fi
    # Security: Ensure it's a regular file in current directory
    if [ "$(dirname "$file")" != "." ]; then
      continue  # Skip files not in current directory
    fi
    
    # Skip lines starting with # (comments)
    # Match: whitespace* provider whitespace* "provider_name" whitespace* {
    if grep -E '^[[:space:]]*provider[[:space:]]+"aws"[[:space:]]*\{' "$file" 2>/dev/null | grep -v '^[[:space:]]*#' | grep -q .; then
      provider="aws"
      provider_found=true
      break
    elif grep -E '^[[:space:]]*provider[[:space:]]+"google"[[:space:]]*\{' "$file" 2>/dev/null | grep -v '^[[:space:]]*#' | grep -q .; then
      provider="google"
      provider_found=true
      break
    elif grep -E '^[[:space:]]*provider[[:space:]]+"azurerm"[[:space:]]*\{' "$file" 2>/dev/null | grep -v '^[[:space:]]*#' | grep -q .; then
      provider="azurerm"
      provider_found=true
      break
    fi
  done
  
  # Security: Validate provider is one of the allowed values
  case "$provider" in
    aws|google|azurerm)
      # Valid provider
      ;;
    *)
      echo "❌ Error: Invalid provider detected: $provider" >&2
      return 1
      ;;
  esac
  
  # Check if provider block already exists
  local existing_provider=""
  if [ "$provider_found" = true ]; then
    existing_provider=$(detect_existing_provider "$provider")
  fi
  
  if [ -n "$existing_provider" ]; then
    # Provider block exists - generate variables file and patch instructions
    local provider_file=$(echo "$existing_provider" | cut -d: -f1)
    local provider_line=$(echo "$existing_provider" | cut -d: -f2)
    
    # Security: Validate provider_file to prevent path traversal
    # Only allow filenames in current directory (no path separators)
    if [[ "$provider_file" == *"/"* ]] || [[ "$provider_file" == *".."* ]]; then
      echo "❌ Error: Invalid provider file path detected" >&2
      return 1
    fi
    
    # Validate provider_file exists and is a regular file in current directory
    if [ ! -f "$provider_file" ] || [ "$(dirname "$provider_file")" != "." ]; then
      echo "❌ Error: Provider file validation failed" >&2
      return 1
    fi
    
    # Generate locals block for Azure/GCP (AWS doesn't need it)
    local locals_block=""
    if [ "$provider" = "azurerm" ]; then
      locals_block="

# Default tags that will be applied to all resources
locals {
  default_tags = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
  }
}"
    elif [ "$provider" = "google" ]; then
      locals_block="

# Default labels that can be applied to resources
locals {
  default_labels = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
  }
}"
    fi
    
    # Write variables file (and locals for Azure/GCP)
    cat > "$filename" <<VAREOF
# ===============================================
# trupositive generated file
# ===============================================
# This file was generated by 'trupositive init'
# It auto-configures Git tagging in Terraform.
# Safe to delete! Do not modify the generated file.
# ===============================================

variable "git_sha" {
  type    = string
  default = "unknown"
}

variable "git_branch" {
  type    = string
  default = "unknown"
}

variable "git_repo" {
  type    = string
  default = "unknown"
}
$locals_block
VAREOF
    
    echo ""
    if [ "$provider" = "aws" ]; then
      echo "✨ Created trupositive.auto.tf (variables only)"
    else
      echo "✨ Created trupositive.auto.tf (variables and locals block)"
    fi
    echo ""
    echo "⚠️  Provider block already exists in: $provider_file (line $provider_line)"
    echo ""
    if [ "$provider" = "aws" ]; then
      echo "To enable automatic tagging, add the following to your existing"
      echo "provider \"$provider\" block in $provider_file:"
    else
      echo "To enable automatic tagging, add the following configuration"
      echo "to your Terraform files:"
    fi
    echo ""
    generate_provider_patch "$provider" "$provider_file" "$provider_line"
    echo ""
    if [ "$provider" = "aws" ]; then
      echo "After adding default_tags, commit both files:"
    else
      echo "After adding the configuration, commit both files:"
    fi
    # Security: Sanitize provider_file for display (already validated above)
    local safe_provider_file="$provider_file"
    echo "  git add trupositive.auto.tf $safe_provider_file"
    echo "  git commit -m \"Enable trupositive Terraform tagging\""
    echo ""
    
  else
    # No provider block exists - generate complete file
    local provider_block=""
    case "$provider" in
      aws)
        provider_block="provider \"aws\" {
  default_tags {
    tags = {
      git_sha    = var.git_sha
      git_branch = var.git_branch
      git_repo   = var.git_repo
    }
  }
}"
        ;;
      google)
        provider_block="provider \"google\" {
  # GCP configuration
}

# Default labels that can be applied to resources
# Note: GCP uses labels instead of tags, and provider-wide defaults aren't uniform.
# You may need to add labels per resource or use a module.
locals {
  default_labels = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
  }
}

# Example usage:
# resource \"google_storage_bucket\" \"example\" {
#   name     = \"example\"
#   ...
#   labels = local.default_labels
# }
#
# See: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#labels
"
        ;;
      azurerm)
        provider_block="provider \"azurerm\" {
  features {}
}

# Default tags that will be applied to all resources
locals {
  default_tags = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
  }
}"
        ;;
    esac
    
    # Write the complete file
    cat > "$filename" <<FULLEOF
# ===============================================
# trupositive generated file
# ===============================================
# This file was generated by 'trupositive init'
# It auto-configures Git tagging in Terraform.
# Safe to delete! Do not modify the generated file.
# ===============================================

variable "git_sha" {
  type    = string
  default = "unknown"
}

variable "git_branch" {
  type    = string
  default = "unknown"
}

variable "git_repo" {
  type    = string
  default = "unknown"
}

$provider_block
FULLEOF
    
    echo ""
    echo "✨ Created trupositive.auto.tf"
    echo "✔  Git tagging configured automatically (detected provider: $provider)"
    echo "🔁 Safe to delete the file if you change your tagging strategy"
    echo "📝 Commit the file if you want permanent tagging"
    echo ""
  fi
}

# Handle init command
if [ "$1" = "init" ]; then
  # Detect infrastructure tool
  if ! detect_infra_tool; then
    echo "❌ Error: No Terraform or CloudFormation files found" >&2
    echo "   Please run 'trupositive init' from a Terraform or CloudFormation project directory" >&2
    exit 1
  fi
  
  case "$INFRA_TOOL" in
    terraform)
      echo "🔍 Detected Terraform project"
      run_init
      ;;
    cloudformation)
      echo "🔍 Detected CloudFormation project"
      run_init_cloudformation
      ;;
    *)
      echo "❌ Error: Unknown infrastructure tool" >&2
      exit 1
      ;;
  esac
  exit $?
fi

# For all other commands, detect tool and pass through to appropriate wrapper
if ! detect_infra_tool; then
    # If we can't detect, default to terraform for backward compatibility
    INFRA_TOOL="terraform"
fi

case "$INFRA_TOOL" in
  terraform)
    # Find terraform-real to avoid infinite loop
    # Priority: terraform-real (from installation) > which terraform > terraform in PATH
    TERRAFORM_WRAPPER=""
    if [ -f ~/.local/bin/terraform-real ]; then
        TERRAFORM_WRAPPER=~/.local/bin/terraform-real
    elif command -v terraform-real >/dev/null 2>&1; then
        TERRAFORM_WRAPPER=$(command -v terraform-real)
    elif [ -f ~/.local/bin/terraform ]; then
        # Use the wrapper if it exists
        TERRAFORM_WRAPPER=~/.local/bin/terraform
    elif command -v terraform >/dev/null 2>&1; then
        TERRAFORM_WRAPPER=$(command -v terraform)
    else
        echo "Error: terraform binary not found. Please install Terraform." >&2
        exit 1
    fi
    exec "$TERRAFORM_WRAPPER" "$@"
    ;;
    
  cloudformation)
    # Find cloudformation wrapper
    CLOUDFORMATION_WRAPPER=""
    if [ -f ~/.local/bin/cloudformation ]; then
        CLOUDFORMATION_WRAPPER=~/.local/bin/cloudformation
    elif command -v cloudformation >/dev/null 2>&1; then
        CLOUDFORMATION_WRAPPER=$(command -v cloudformation)
    else
        echo "Error: cloudformation wrapper not found. Please install trupositive properly." >&2
        exit 1
    fi
    # Pass arguments to cloudformation wrapper (it handles both direct and proxied calls)
    exec "$CLOUDFORMATION_WRAPPER" "$@"
    ;;
    
  *)
    echo "Error: Unknown infrastructure tool" >&2
    exit 1
    ;;
esac
EOFTP

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
