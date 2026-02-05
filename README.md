# trupositive

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/trupositive-ai/trupositive/releases)

**Automatically tag all your infrastructure with Git metadata** - commit SHA, branch, and repo. Zero config. Works with Terraform and AWS CloudFormation.

## What Problem Does This Solve?

When infrastructure breaks in production, you need to know **exactly which code version deployed it**. Manual tagging is error-prone and forgotten. trupositive automatically injects Git metadata into every resource, enabling:

- **Instant root cause analysis** - trace any resource back to its exact code commit
- **Compliance & audit trails** - automatic documentation of what changed and when
- **Rollback confidence** - know exactly which Git SHA to revert to
- **Change tracking** - correlate infrastructure changes with code changes

## Who Is This For?

- **DevOps Engineers** - Automate tagging without changing workflows
- **SREs** - Faster incident response with instant Git SHA tracing
- **Platform Teams** - Enforce tagging standards across all teams automatically
- **FinOps** - Track cost changes back to specific code changes and teams

## When Should You NOT Use This?

Don't use trupositive if:

- **You deploy from non-Git sources** (manual uploads, artifact registries)
- **You have existing Git tagging automation** that works for you
- **Your compliance requires manual tag approval** before deployment

## Try It in 5 Minutes

```bash
# 1. Install (30 seconds)
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"

# 2. Generate config (10 seconds)
cd your-terraform-or-cloudformation-project
trupositive init

# 3. Deploy - Git metadata automatically injected (4 minutes)
terraform apply    # or: aws cloudformation deploy --template-file template.yaml --stack-name my-stack

# ✅ All resources now tagged with git_sha, git_branch, git_repo
```

### Example Output

**Terraform - Automatic tagging configuration generated:**
```hcl
# trupositive.auto.tf
variable "git_sha" { default = "a1b2c3d" }
variable "git_branch" { default = "main" }
variable "git_repo" { default = "github.com/org/repo" }

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

**CloudFormation - Resources deployed with Git metadata:**
```bash
$ aws cloudformation describe-stacks --stack-name my-app --query 'Stacks[0].Tags'
[
  { "Key": "git_sha", "Value": "a1b2c3d4e5f" },
  { "Key": "git_branch", "Value": "main" },
  { "Key": "git_repo", "Value": "github.com/yourorg/yourapp" }
]
```

**AWS Console - Every resource automatically tagged:**
```
EC2 Instance i-abc123:
  ├─ git_sha: a1b2c3d4e5f
  ├─ git_branch: main
  └─ git_repo: github.com/yourorg/yourapp

S3 Bucket my-bucket:
  ├─ git_sha: a1b2c3d4e5f
  ├─ git_branch: main
  └─ git_repo: github.com/yourorg/yourapp
```

> **Latest Release:** v1.1.0 - Now with CloudFormation support!

## Production Ready

- ✅ **Used in production** by DevOps teams managing multi-account AWS environments
- ✅ **Tested on**: AWS (Terraform + CloudFormation), Azure (Terraform), GCP (Terraform)
- ✅ **CI/CD compatible**: GitHub Actions, GitLab CI, Azure DevOps, Jenkins, CircleCI
- ✅ **Zero runtime dependencies** - pure Bash, works everywhere
- ✅ **Security hardened** - Input sanitization, path traversal protection, no external calls

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

```
┌─────────────────────────────────────────────────────────────────┐
│  Your Terminal                                                  │
│                                                                 │
│  $ terraform apply                                              │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────┐                                           │
│  │ trupositive     │  Detects: Git repo                        │
│  │ wrapper         │  Extracts: commit SHA, branch, repo URL   │
│  └────────┬────────┘  Sanitizes: removes sensitive chars       │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Real terraform  │  Receives: TF_VAR_git_sha=a1b2c3d         │
│  │ binary          │           TF_VAR_git_branch=main          │
│  └────────┬────────┘           TF_VAR_git_repo=github.com/...  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Cloud Provider  │  Resources tagged automatically           │
│  │ (AWS/Azure/GCP) │                                           │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

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

## Trade-offs & Current Design

**What trupositive does well:**
- ✅ Zero-config automatic tagging
- ✅ Works transparently with existing workflows
- ✅ No code changes required
- ✅ Supports both Terraform and CloudFormation
- ✅ CI/CD friendly

**Current design decisions** (open to contribution!):
- 🔧 **Fixed tag names** (`git_sha`, `git_branch`, `git_repo`) - [configurable tags requested](https://github.com/trupositive-ai/trupositive/issues)
- 🔧 **Git repository required** - could support other VCS systems via PRs
- 🔧 **Terraform Azure/GCP** - require manual `tags = local.default_tags` (AWS has provider-level tagging)
- 🔧 **CloudFormation commands** - currently supports `deploy`, `create-stack`, `update-stack`, `create-change-set` (more can be added)
- 🔧 **No tag validation** - compliance checking would be a great addition
- 🔧 **Mono-repo support** - context detection could be improved

💡 **Want to contribute?** These are all great opportunities for PRs! See [CONTRIBUTING.md](CONTRIBUTING.md)

**When to use something else:**
- Need custom tag key names **right now** → Use native provider tagging (or submit a PR to add this feature!)
- Deploy from non-Git sources → Implement custom tagging in CI/CD
- Require tag approval workflows → Use policy-as-code tools (OPA, Sentinel)
- Complex tag inheritance rules → Use cloud-native tagging strategies

## Requirements

- Git repository
- Bash shell (version 5.0+)
- At least one of:
  - Terraform (for Terraform projects)
  - AWS CLI (for CloudFormation projects)

## Documentation

- **[Examples](examples/)** - Real-world runnable examples for AWS, Azure, GCP
- [Complete Usage Guide](EXAMPLES.md) - Detailed usage documentation
- [Testing Guide](TESTING.md) - How to test the tool
- [Feature Documentation](FEATURE_CLOUDFORMATION.md) - CloudFormation feature details
- [GitHub Optimization](GITHUB_OPTIMIZATION.md) - Discoverability & promotion strategy
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

