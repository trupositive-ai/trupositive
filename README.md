# trupositive

A zero-config Terraform wrapper that automatically injects Git metadata as variables. Works transparently with any Terraform command.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
```

Ensure `~/.local/bin` is in your PATH. Add it temporarily for the current session:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

To make it permanent, add to your shell configuration file:

**For zsh (macOS default):**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**For bash:**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

After adding to PATH, verify the installation:
```bash
which terraform
# Should show: /Users/yourusername/.local/bin/terraform
```

## Uninstallation

```bash
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/uninstall.sh | bash
```

## Usage

Use `terraform` as normal - the wrapper is transparent:

```bash
terraform apply
terraform plan
terraform destroy
```

### Automatic Tagging

Generate Terraform configuration for automatic tagging:

```bash
trupositive init
```

This creates `trupositive.auto.tf` with provider-specific tagging configuration. The tool automatically detects AWS, Azure, or GCP providers.

## How It Works

The wrapper exports Git metadata as Terraform variables:

- `TF_VAR_git_sha` - Current commit SHA
- `TF_VAR_git_branch` - Current branch name  
- `TF_VAR_git_repo` - Remote origin URL

### Provider Support

**AWS:** Uses provider-level `default_tags` - tags applied automatically to all resources.

**Azure/GCP:** Generates `locals` blocks - add `tags = local.default_tags` (or `labels = local.default_labels` for GCP) to resources manually.

## CI/CD

Automatically detects branch names from CI environment variables (GitHub Actions, GitLab CI, Azure DevOps, Jenkins).

## Requirements

- Git repository
- Terraform installed
- Bash shell

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

Report security issues to [SECURITY.md](SECURITY.md).
