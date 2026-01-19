# Testing Guide

This guide helps you test trupositive as a new user would experience it.

## Prerequisites

- Git installed
- Terraform installed
- Bash shell
- A test directory for Terraform projects

## Step 1: Clean Installation Test

Test the installation process from scratch:

```bash
# Create a clean test environment
mkdir -p ~/test-trupositive
cd ~/test-trupositive

# Remove any existing installation
rm -rf ~/.local/bin/terraform ~/.local/bin/trupositive ~/.local/bin/terraform-real

# Test the installation command from README
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash

# Verify installation
which terraform
which trupositive
ls -la ~/.local/bin/terraform*
```

**Expected results:**
- `terraform` should point to `~/.local/bin/terraform`
- `trupositive` should exist at `~/.local/bin/trupositive`
- `terraform-real` should exist (backup of original terraform)

## Step 2: Test Wrapper Functionality

Test that the wrapper injects Git metadata:

```bash
# Create a test git repository
mkdir -p ~/test-tf-project
cd ~/test-tf-project
git init
echo "# Test" > README.md
git add README.md
git config user.email "test@example.com"
git config user.name "Test User"
git commit -m "Initial commit"

# Create a simple Terraform file
cat > main.tf <<EOF
variable "git_sha" {
  type = string
  default = "unknown"
}

variable "git_branch" {
  type = string
  default = "unknown"
}

variable "git_repo" {
  type = string
  default = "unknown"
}

output "git_sha" {
  value = var.git_sha
}

output "git_branch" {
  value = var.git_branch
}

output "git_repo" {
  value = var.git_repo
}
EOF

# Test terraform wrapper
terraform init
terraform apply -auto-approve

# Check outputs - should show git metadata
terraform output
```

**Expected results:**
- `git_sha` should show the current commit SHA
- `git_branch` should show the branch name (likely "main" or "master")
- `git_repo` should show the git remote URL (if configured)

## Step 3: Test trupositive init Command

Test the automatic tagging setup:

```bash
# Create a new test project
mkdir -p ~/test-aws-project
cd ~/test-aws-project
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create a basic AWS provider file
cat > main.tf <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF

# Run trupositive init
trupositive init

# Verify the generated file
cat trupositive.auto.tf

# Check that it includes variables and provider block
grep -q "variable \"git_sha\"" trupositive.auto.tf && echo "✓ Variables found"
grep -q "default_tags" trupositive.auto.tf && echo "✓ Default tags found"
```

**Expected results:**
- `trupositive.auto.tf` should be created
- Should contain variable definitions for git_sha, git_branch, git_repo
- Should contain AWS provider block with default_tags

## Step 4: Test with Different Providers

Test provider detection:

```bash
# Test Azure provider detection
mkdir -p ~/test-azure-project
cd ~/test-azure-project
git init
git config user.email "test@example.com"
git config user.name "Test User"

cat > main.tf <<EOF
provider "azurerm" {
  features {}
}
EOF

trupositive init
cat trupositive.auto.tf
# Should contain locals block with default_tags

# Test GCP provider detection
mkdir -p ~/test-gcp-project
cd ~/test-gcp-project
git init
git config user.email "test@example.com"
git config user.name "Test User"

cat > main.tf <<EOF
provider "google" {
  project = "test-project"
}
EOF

trupositive init
cat trupositive.auto.tf
# Should contain locals block with default_labels
```

## Step 5: Test Error Cases

Test that errors are handled gracefully:

```bash
# Test without git repository
mkdir -p ~/test-no-git
cd ~/test-no-git
terraform plan 2>&1
# Should work but git variables will be empty

# Test without .tf files
mkdir -p ~/test-no-tf
cd ~/test-no-tf
trupositive init 2>&1
# Should show error about no .tf files

# Test init when file already exists
cd ~/test-aws-project
trupositive init 2>&1
# Should show error about file already existing
```

## Step 6: Test Uninstallation

Test the uninstall process:

```bash
# Run uninstall
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/uninstall.sh | bash

# Verify removal
which terraform
# Should show system terraform, not wrapper

ls -la ~/.local/bin/terraform*
# Wrapper should be removed, terraform-real might still exist
```

## Step 7: Test PATH Handling

Test that PATH ordering works correctly:

```bash
# Reinstall
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash

# Check PATH
echo $PATH | grep -q "$HOME/.local/bin" && echo "✓ ~/.local/bin in PATH" || echo "✗ ~/.local/bin NOT in PATH"

# Test terraform resolution
terraform version
# Should use wrapper

# Test with explicit PATH
PATH="/usr/local/bin:$PATH" terraform version
# Might use system terraform if PATH doesn't include ~/.local/bin
```

## Step 8: Test in CI/CD Environment

Simulate CI environment variables:

```bash
# Test with GitHub Actions environment
export GITHUB_REF_NAME="feature/test-branch"
cd ~/test-tf-project
terraform apply -auto-approve
terraform output git_branch
# Should show "feature/test-branch"

# Test with GitLab CI
unset GITHUB_REF_NAME
export CI_COMMIT_REF_NAME="gitlab-branch"
terraform apply -auto-approve
terraform output git_branch
# Should show "gitlab-branch"
```

## Step 9: Full Integration Test

Test a complete workflow:

```bash
# Create a realistic project
mkdir -p ~/test-full-project
cd ~/test-full-project
git init
git remote add origin https://github.com/testuser/testrepo.git
git config user.email "test@example.com"
git config user.name "Test User"

# Create Terraform files
cat > main.tf <<EOF
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "test" {
  bucket = "test-bucket-\${var.git_sha}"
  
  tags = {
    GitBranch = var.git_branch
    GitRepo   = var.git_repo
  }
}
EOF

# Initialize with trupositive
trupositive init

# Verify the setup
terraform init
terraform validate

# Check that variables are available
terraform plan
# Should show git metadata in the plan
```

## Troubleshooting

If tests fail:

1. **terraform not found**: Ensure Terraform is installed and in PATH
2. **Permission denied**: Check `~/.local/bin` is writable
3. **Git errors**: Ensure you're in a git repository for metadata tests
4. **Wrapper not found**: Verify installation completed successfully

## Cleanup

After testing, clean up:

```bash
# Remove test directories
rm -rf ~/test-trupositive ~/test-tf-project ~/test-aws-project ~/test-azure-project ~/test-gcp-project ~/test-no-git ~/test-no-tf ~/test-full-project

# Uninstall trupositive
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/uninstall.sh | bash
```
