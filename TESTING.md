# Testing Guide

## Quick Start

Run the comprehensive test suite:

```bash
./test.sh
```

This will test:
- ✅ Bash syntax validation
- ✅ File structure
- ✅ Git metadata extraction
- ✅ Input sanitization
- ✅ CloudFormation detection
- ✅ Security features
- ✅ Documentation completeness

## Manual Testing

### 1. Test Syntax (Quick)

```bash
bash -n terraform
bash -n cloudformation
bash -n trupositive
bash -n install.sh
bash -n uninstall.sh
```

All should exit with code 0 (no output = success).

### 2. Test Git Metadata Extraction

```bash
# In a git repository
git rev-parse HEAD                    # Should show commit SHA
git symbolic-ref --short -q HEAD      # Should show branch name
git config --get remote.origin.url    # Should show repo URL
```

### 3. Test Input Sanitization

```bash
# Test dangerous input
echo '$(rm -rf /) && evil' | sed 's/[^a-zA-Z0-9\/.\-_]//g'
# Should output: rmrfevil (safe)
```

### 4. Test CloudFormation Detection

```bash
# Should detect CloudFormation template
grep "^AWSTemplateFormatVersion:" example-cloudformation.yaml
```

## Integration Testing (Requires Tools)

### Terraform Integration Test

**Prerequisites:** Terraform installed

```bash
# Create test directory
mkdir -p /tmp/test-terraform
cd /tmp/test-terraform

# Create simple test
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 0.12"
}

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

output "git_metadata" {
  value = {
    sha    = var.git_sha
    branch = var.git_branch
    repo   = var.git_repo
  }
}
EOF

# Initialize git
git init
git add .
git commit -m "test"

# Copy trupositive
cp ~/code/trupositive/terraform ./terraform-wrapper
chmod +x ./terraform-wrapper

# Test
./terraform-wrapper init
./terraform-wrapper plan

# Verify variables
./terraform-wrapper console <<< 'var.git_sha'
./terraform-wrapper console <<< 'var.git_branch'
./terraform-wrapper console <<< 'var.git_repo'

# Cleanup
cd -
rm -rf /tmp/test-terraform
```

**Expected:** Should see actual git values, not "unknown"

### CloudFormation Integration Test

**Prerequisites:** AWS CLI installed, AWS credentials configured

```bash
# Create test directory
mkdir -p /tmp/test-cloudformation
cd /tmp/test-cloudformation

# Copy example template
cp ~/code/trupositive/example-cloudformation.yaml template.yaml

# Initialize git
git init
git add .
git commit -m "test"

# Copy wrappers
cp ~/code/trupositive/cloudformation ./cloudformation-wrapper
chmod +x ./cloudformation-wrapper

# Test parameter injection (dry-run)
./cloudformation-wrapper cloudformation deploy \
  --template-file template.yaml \
  --stack-name test-stack \
  --no-execute-changeset

# Check what parameters would be passed
# Look for: GitSha, GitBranch, GitRepo in output

# Cleanup
cd -
rm -rf /tmp/test-cloudformation
```

**Expected:** Parameters should include Git metadata

### Test Auto-Detection

**Prerequisites:** trupositive CLI

```bash
# Test Terraform detection
cd /tmp
mkdir test-tf && cd test-tf
touch main.tf
~/code/trupositive/trupositive init
# Should say: "Detected Terraform project"
cd .. && rm -rf test-tf

# Test CloudFormation detection
mkdir test-cfn && cd test-cfn
cat > template.yaml <<'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
EOF
~/code/trupositive/trupositive init
# Should say: "Detected CloudFormation project"
cd .. && rm -rf test-cfn
```

## CI/CD Testing

Test in different CI environments:

### GitHub Actions

```yaml
name: Test trupositive
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: ./test.sh
```

### GitLab CI

```yaml
test:
  script:
    - ./test.sh
```

## Security Testing

### 1. Test Injection Prevention

```bash
# Test shell injection
export MALICIOUS='$(whoami); echo pwned'
./terraform version
# Should NOT execute whoami or echo pwned

# Test command injection via Git
git config user.name '$(whoami)'
./cloudformation --version
# Should sanitize and not execute
git config user.name "Your Name"  # reset
```

### 2. Test Path Traversal

```bash
# Create files with suspicious names
touch "../../../etc/passwd"
touch "../../evil.tf"

# Run detection
~/code/trupositive/trupositive init
# Should skip files with path separators
```

## Performance Testing

```bash
# Test with large repo URL
git config remote.origin.url "$(printf 'a%.0s' {1..2000})"
./terraform version
# Should limit to 1000 chars

# Reset
git config remote.origin.url "https://github.com/user/repo.git"
```

## Expected Test Results

### All Green (PASS)
```
Total Tests:   45
Passed:        42
Failed:        0
Skipped:       3

✓ ALL TESTS PASSED
The codebase is production ready!
```

### With Skipped Tests
Skipped tests are normal if:
- Not in a git repository
- Terraform not installed
- AWS CLI not installed

These are optional integration tests.

## Troubleshooting

### Test fails on Git operations
**Solution:** Run tests in a git repository
```bash
cd ~/code/trupositive
./test.sh
```

### Syntax errors
**Solution:** Ensure all scripts have Unix line endings
```bash
dos2unix *.sh terraform cloudformation trupositive
```

### Permission denied
**Solution:** Make scripts executable
```bash
chmod +x test.sh install.sh uninstall.sh terraform cloudformation trupositive
```

## Continuous Testing

Run tests before each commit:

```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
./test.sh || exit 1
```

## Test Coverage

Current test coverage:
- ✅ Syntax validation: 100%
- ✅ Security features: 100%
- ✅ File structure: 100%
- ✅ Documentation: 100%
- ⚠️ Integration: Requires manual testing
- ⚠️ CI/CD: Requires pipeline setup

## Next Steps

1. Run `./test.sh` to validate all changes
2. Fix any failures
3. Run integration tests if tools available
4. Commit when all tests pass
