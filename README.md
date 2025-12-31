# terraform-git-wrapper

A zero-config Terraform wrapper that automatically injects Git metadata as variables. The wrapper replaces `terraform` in your PATH, making it completely transparent to use.

## Installation

### One-Line Installer (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/simmestdagh/tf-git/main/install.sh | bash
```

**Important:** After installation, make sure `~/.local/bin` is in your PATH. Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Manual Installation

#### Step 1: Find and rename the real Terraform binary

```bash
# Find where terraform is installed
which terraform

# Example output: /usr/local/bin/terraform
# Rename it to terraform-real
sudo mv /usr/local/bin/terraform /usr/local/bin/terraform-real
```

#### Step 2: Install the wrapper

```bash
# Clone the repository
git clone https://github.com/simmestdagh/tf-git.git
cd tf-git

# Install to ~/.local/bin
mkdir -p ~/.local/bin
cp terraform ~/.local/bin/terraform
chmod +x ~/.local/bin/terraform

# Make sure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"
```

## Uninstallation

To remove the wrapper and optionally restore the original terraform:

```bash
curl -fsSL https://raw.githubusercontent.com/simmestdagh/tf-git/main/uninstall.sh | bash
```

Or run manually:

```bash
./uninstall.sh
```

## Usage

### Basic Usage

Just use `terraform` as normal - the wrapper is completely transparent:

```bash
terraform apply
terraform plan
terraform destroy
# ... any terraform command
```

### Automatic Terraform Tagging (Optional)

If you want Terraform-native automatic tagging using provider `default_tags`:

1. **Run the init command:**
   ```bash
   tf-git init
   ```

2. **Review the generated file:**
   The command creates `tf-git.auto.tf` with:
   - Variable definitions for Git metadata
   - Provider block with `default_tags` configured

3. **Commit the generated file:**
   ```bash
   git add tf-git.auto.tf
   git commit -m "Enable tf-git Terraform tagging"
   ```

4. **Run Terraform as normal:**
   ```bash
   terraform apply
   ```

The generated file is:
- ✅ Safe to delete
- ✅ Clearly labeled as generated
- ✅ Only created on request
- ✅ Automatically detected by Terraform (`.auto.tf` files are loaded automatically)

**Provider Detection:** The init command automatically detects your cloud provider (AWS, Azure, or GCP) by scanning existing `.tf` files.

**Important:** If a provider block already exists in your codebase, `tf-git init` will:
- Generate only the variable definitions in `tf-git.auto.tf`
- Provide instructions and a patch to add `default_tags` to your existing provider block

This prevents duplicate provider configuration errors. You'll need to manually add the `default_tags` block to your existing provider configuration (the command will show you exactly what to add).

**Note on GCP:** GCP uses labels instead of tags, and provider-wide defaults aren't uniform. You may need to add labels per resource or use a module for GCP projects.

## Provider-Specific Notes

### AWS Provider

AWS supports provider-level `default_tags` which automatically applies tags to all resources:

```hcl
provider "aws" {
  default_tags {
    tags = {
      git_sha    = var.git_sha
      git_branch = var.git_branch
      git_repo   = var.git_repo
    }
  }
}
```

This works automatically - no manual tagging needed!

### Azure Provider

**Important:** The Azure provider (`azurerm`) does **NOT** support provider-level `default_tags` like AWS. Instead, `tf-git init` generates a `locals` block:

```hcl
locals {
  default_tags = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
  }
}
```

You need to manually add `tags = local.default_tags` to each resource:

```hcl
resource "azurerm_storage_account" "example" {
  name     = "example"
  location = "westeurope"
  ...
  tags = local.default_tags
}
```

### GCP Provider

GCP uses labels instead of tags, and provider-wide defaults aren't uniform. `tf-git init` generates a `locals` block with `default_labels`:

```hcl
locals {
  default_labels = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
  }
}
```

Add `labels = local.default_labels` to each resource that supports labels:

```hcl
resource "google_storage_bucket" "example" {
  name     = "example"
  ...
  labels = local.default_labels
}
```

See the [GCP provider documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#labels) for more details.

## How It Works

When you run `terraform apply`, what actually happens is:

```
terraform (wrapper)
  → inject git vars
  → terraform-real apply
```

The wrapper automatically extracts Git metadata and exports it as Terraform variables:

- `TF_VAR_git_sha` - Current commit SHA
- `TF_VAR_git_branch` - Current branch name  
- `TF_VAR_git_repo` - Remote origin URL

Terraform is completely unaware of the wrapper.

## Terraform Configuration

### Option 1: Automatic Tagging (Recommended)

Run `tf-git init` to automatically generate `tf-git.auto.tf` with provider configuration.

**AWS:** Uses provider-level `default_tags` - tags are applied automatically to all resources.

**Azure/GCP:** Generates a `locals` block - you'll need to add `tags = local.default_tags` (or `labels = local.default_labels` for GCP) to each resource manually.

### Option 2: Manual Configuration

If you prefer manual tagging, define the variables in your Terraform code:

```hcl
variable "git_sha" {
  type = string
  default = ""
}

variable "git_branch" {
  type = string
  default = ""
}

variable "git_repo" {
  type = string
  default = ""
}

locals {
  default_tags = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "example"
  location = "westeurope"
  tags     = local.default_tags
}
```

## Upgrading Terraform

After upgrading Terraform, re-run the installer to update the `terraform-real` binary:

```bash
curl -fsSL https://raw.githubusercontent.com/simmestdagh/tf-git/main/install.sh | bash
```

The installer will detect and update the `terraform-real` binary if needed.

## Requirements

- Git repository
- Terraform installed (will be copied to `terraform-real` in `~/.local/bin`)
- Bash shell

## CI/CD Considerations

The wrapper handles common CI scenarios:
- **Detached HEAD:** Automatically detects branch from CI environment variables (GitHub Actions, GitLab CI, Azure DevOps, etc.)
- **Shallow clones:** Works with shallow checkouts (ensure `fetch-depth` includes the commit)
- **No Git repo:** Gracefully falls back to empty strings if not in a Git repository
