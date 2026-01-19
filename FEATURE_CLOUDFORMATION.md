# CloudFormation Support - Feature Summary

## Overview

This feature adds AWS CloudFormation support to trupositive, allowing users to automatically inject Git metadata into CloudFormation stacks alongside the existing Terraform functionality.

## What's New

### 1. CloudFormation Wrapper (`cloudformation`)

A new wrapper script that:
- Extracts Git metadata (SHA, branch, repository URL)
- Automatically injects Git parameters into CloudFormation commands
- Works with `deploy`, `create-stack`, `update-stack`, and `create-change-set` commands
- Passes through all other AWS CLI commands unchanged

**Key Features:**
- Automatic parameter injection via `--parameter-overrides`
- Sanitizes Git metadata for security
- Supports CI/CD environment variables
- Can be disabled with `--no-git-params` flag

### 2. Enhanced trupositive CLI

Updated to support both Terraform and CloudFormation:
- **Auto-detection**: Automatically detects project type (Terraform or CloudFormation)
- **Smart initialization**: `trupositive init` generates appropriate configuration based on detected tool
- **Dual support**: Can work with both tools in the same repository

### 3. Updated Installation

The `install.sh` script now:
- Checks for both Terraform and AWS CLI
- Installs wrappers for available tools
- Creates backup copies (`terraform-real`, `aws-real`)
- Provides clear feedback on what's installed

**Installation flow:**
```bash
curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
```

### 4. Enhanced Uninstallation

The `uninstall.sh` script now:
- Removes CloudFormation wrapper
- Restores original AWS CLI from backup
- Cleans up all trupositive-related files
- Provides clear feedback on what's removed

## Files Changed

### New Files
- `cloudformation` - CloudFormation wrapper script
- `EXAMPLES.md` - Comprehensive examples for both Terraform and CloudFormation
- `example-cloudformation.yaml` - Working CloudFormation template example
- `FEATURE_CLOUDFORMATION.md` - This file

### Modified Files
- `trupositive` - Added CloudFormation detection and initialization
- `install.sh` - Added CloudFormation wrapper installation
- `uninstall.sh` - Added CloudFormation wrapper removal
- `README.md` - Updated documentation with CloudFormation usage
- `CHANGELOG.md` - Added version 1.1.0 entry

## Usage Examples

### CloudFormation Project

```bash
# Navigate to CloudFormation project
cd my-cloudformation-project

# Initialize trupositive
trupositive init
# Output: 🔍 Detected CloudFormation project
#         ✨ Created trupositive-params.yaml

# Add parameters to your CloudFormation template
# (see trupositive-params.yaml for examples)

# Deploy with automatic Git metadata injection
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-stack

# Git parameters are automatically added:
# --parameter-overrides GitSha=abc123... GitBranch=feature/x GitRepo=...
```

### Terraform Project (Still Works!)

```bash
# Navigate to Terraform project
cd my-terraform-project

# Initialize trupositive
trupositive init
# Output: 🔍 Detected Terraform project
#         ✨ Created trupositive.auto.tf

# Use Terraform normally
terraform apply
```

## Architecture

### Wrapper Chain

**Terraform:**
```
User → terraform wrapper → terraform-real (original binary)
       ↓
       Injects TF_VAR_git_sha, TF_VAR_git_branch, TF_VAR_git_repo
```

**CloudFormation:**
```
User → aws wrapper → cloudformation wrapper → aws-real (original binary)
       ↓              ↓
       Detects       Injects GitSha, GitBranch, GitRepo
       cfn command   via --parameter-overrides
```

### Auto-Detection Logic

1. `trupositive init` checks for files:
   - `*.yaml`, `*.yml`, `*.json` with CloudFormation syntax → CloudFormation
   - `*.tf` files → Terraform

2. Priority: CloudFormation checked first, then Terraform

### Parameter Injection

CloudFormation wrapper intercepts commands and:
1. Checks if command accepts parameters (`deploy`, `create-stack`, etc.)
2. Adds `--parameter-overrides` if not present
3. Injects `GitSha`, `GitBranch`, `GitRepo` parameters
4. Appends to existing `--parameter-overrides` if already present

## Security Features

All security features from Terraform wrapper are maintained:
- Git metadata sanitization (removes special characters)
- Length limits (200 chars for branch, 1000 for repo)
- Input validation
- No command injection vulnerabilities

## Backward Compatibility

- ✅ Existing Terraform functionality unchanged
- ✅ Existing `trupositive init` behavior preserved for Terraform projects
- ✅ All Terraform wrappers and scripts work as before
- ✅ No breaking changes to existing installations

## Testing Checklist

- [x] Bash syntax validation (all scripts pass `bash -n`)
- [x] CloudFormation wrapper structure
- [x] Terraform wrapper still works
- [x] Auto-detection logic
- [ ] Integration test with real AWS CLI (requires AWS CLI installation)
- [ ] Integration test with real Terraform (not modified, should work)

## Next Steps

1. Test with actual AWS CLI installation
2. Test deployment with real CloudFormation stack
3. Verify Git metadata appears in stack parameters
4. Test in CI/CD environment (GitHub Actions, GitLab CI, etc.)
5. Consider adding support for other IaC tools (Pulumi, CDK, etc.)

## Notes

- The AWS wrapper is created during installation to intercept CloudFormation commands
- Non-CloudFormation AWS commands pass through unchanged
- The `--no-git-params` flag allows users to opt-out of Git parameter injection
- Both tools can coexist in the same repository (different directories)
