# trupositive

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/trupositive-ai/trupositive/releases)

A zero-config infrastructure-as-code wrapper that automatically injects Git metadata. Supports both **Terraform** and **AWS CloudFormation**. Works transparently with any command.

> **Latest Release:** v1.1.0 - Now with CloudFormation support!

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
```

**Requirements:** Install at least one of the following before running the installer:
- Terraform (for Terraform projects)
- AWS CLI (for CloudFormation projects)

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

**For Terraform:**
```bash
which terraform
# Should show: /Users/yourusername/.local/bin/terraform
```

**For CloudFormation:**
```bash
which aws
# Should show: /Users/yourusername/.local/bin/aws
```

## Uninstallation

```bash
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/uninstall.sh | bash
```

## Usage

### Terraform

Use `terraform` as normal - the wrapper is transparent:

```bash
terraform apply
terraform plan
terraform destroy
```

Generate Terraform configuration for automatic tagging:

```bash
trupositive init
```

This creates `trupositive.auto.tf` with provider-specific tagging configuration. The tool automatically detects AWS, Azure, or GCP providers.

### CloudFormation

Use `aws cloudformation` as normal - the wrapper automatically injects Git metadata:

```bash
aws cloudformation deploy --template-file template.yaml --stack-name my-stack
aws cloudformation create-stack --template-file template.yaml --stack-name my-stack
aws cloudformation update-stack --template-file template.yaml --stack-name my-stack
```

Generate CloudFormation parameter definitions and examples:

```bash
trupositive init
```

This creates `trupositive-params.yaml` with parameter definitions and usage examples for adding Git metadata tags to your resources.

## How It Works

### Terraform

The wrapper exports Git metadata as Terraform variables:

- `TF_VAR_git_sha` - Current commit SHA
- `TF_VAR_git_branch` - Current branch name  
- `TF_VAR_git_repo` - Remote origin URL

**Provider Support:**

- **AWS:** Uses provider-level `default_tags` - tags applied automatically to all resources.
- **Azure/GCP:** Generates `locals` blocks - add `tags = local.default_tags` (or `labels = local.default_labels` for GCP) to resources manually.

### CloudFormation

The wrapper automatically injects Git metadata as CloudFormation parameters:

- `GitSha` - Current commit SHA
- `GitBranch` - Current branch name
- `GitRepo` - Remote origin URL

These parameters are automatically passed to `deploy`, `create-stack`, `update-stack`, and `create-change-set` commands via `--parameter-overrides`.

**Usage in templates:**

```yaml
Parameters:
  GitSha:
    Type: String
    Default: "unknown"
  GitBranch:
    Type: String
    Default: "unknown"
  GitRepo:
    Type: String
    Default: "unknown"

Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: git_sha
          Value: !Ref GitSha
        - Key: git_branch
          Value: !Ref GitBranch
        - Key: git_repo
          Value: !Ref GitRepo
```

## CI/CD

Automatically detects branch names from CI environment variables (GitHub Actions, GitLab CI, Azure DevOps, Jenkins).

## Requirements

- Git repository
- Bash shell
- At least one of:
  - Terraform (for Terraform projects)
  - AWS CLI (for CloudFormation projects)

## Documentation

- [Examples](EXAMPLES.md) - Complete usage examples
- [Testing Guide](TESTING.md) - How to test the tool
- [Feature Documentation](FEATURE_CLOUDFORMATION.md) - CloudFormation feature details
- [Contributing](CONTRIBUTING.md) - How to contribute
- [Security Policy](SECURITY.md) - Security guidelines
- [Changelog](CHANGELOG.md) - Version history

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

Report security issues per [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) - Copyright (c) 2024-2026 trupositive-ai

---

