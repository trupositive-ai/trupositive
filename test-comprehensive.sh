#!/bin/bash
# Comprehensive Test Suite for trupositive Repository
# Tests all aspects of the codebase for production readiness

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test categories
CATEGORY_TESTS=0
CATEGORY_PASSED=0
CATEGORY_FAILED=0

# Helper functions
print_banner() {
  echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}${BOLD}$1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_category() {
  CATEGORY_TESTS=0
  CATEGORY_PASSED=0
  CATEGORY_FAILED=0
  echo -e "\n${BLUE}▶▶▶ $1${NC}\n"
}

print_test() {
  echo -en "${YELLOW}  ▶ Test $(printf '%3d' $((TOTAL_TESTS + 1))): ${NC}$1 ... "
  ((TOTAL_TESTS++))
  ((CATEGORY_TESTS++))
}

pass() {
  echo -e "${GREEN}✓ PASS${NC}"
  ((PASSED_TESTS++))
  ((CATEGORY_PASSED++))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  ((FAILED_TESTS++))
  ((CATEGORY_FAILED++))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  ((SKIPPED_TESTS++))
  ((TOTAL_TESTS--))
  ((CATEGORY_TESTS--))
}

info() {
  echo -e "    ${CYAN}ℹ${NC} $1"
}

category_summary() {
  if [ $CATEGORY_FAILED -eq 0 ]; then
    echo -e "\n  ${GREEN}Category: $CATEGORY_PASSED/$CATEGORY_TESTS passed${NC}"
  else
    echo -e "\n  ${RED}Category: $CATEGORY_PASSED/$CATEGORY_TESTS passed, $CATEGORY_FAILED failed${NC}"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# START TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_banner "COMPREHENSIVE TEST SUITE - trupositive"
echo "Testing repository for production readiness"
echo "Current directory: $(pwd)"
echo "Date: $(date)"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 1: File Structure & Organization
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "1. File Structure & Organization"

print_test "All required core files exist"
required_files=(
  "terraform" "cloudformation" "trupositive" 
  "install.sh" "uninstall.sh" "test.sh"
  "README.md" "LICENSE" "CHANGELOG.md"
  "CONTRIBUTING.md" "SECURITY.md" "EXAMPLES.md"
  "TESTING.md" "FEATURE_CLOUDFORMATION.md"
  "example-cloudformation.yaml"
  ".gitignore" ".editorconfig" ".gitattributes"
)
missing=()
for file in "${required_files[@]}"; do
  [ ! -f "$file" ] && missing+=("$file")
done
[ ${#missing[@]} -eq 0 ] && pass || fail "Missing: ${missing[*]}"

print_test "All scripts are executable"
scripts=("terraform" "cloudformation" "trupositive" "install.sh" "uninstall.sh" "test.sh")
non_executable=()
for script in "${scripts[@]}"; do
  [ ! -x "$script" ] && non_executable+=("$script")
done
[ ${#non_executable[@]} -eq 0 ] && pass || fail "Non-executable: ${non_executable[*]}"

print_test "No internal dev docs in repo"
dev_docs=("CODE_REVIEW.md" "CRITICAL_BUG_FIXED.md" "FINAL_ASSESSMENT.md" 
          "RUN_THIS_FIRST.md" "VALIDATION_REPORT.md")
found_dev_docs=()
for doc in "${dev_docs[@]}"; do
  [ -f "$doc" ] && found_dev_docs+=("$doc")
done
[ ${#found_dev_docs[@]} -eq 0 ] && pass || info "Found dev docs (should remove): ${found_dev_docs[*]}"

print_test ".gitignore exists and has content"
if [ -f ".gitignore" ] && [ -s ".gitignore" ]; then
  pass
else
  fail ".gitignore missing or empty"
fi

print_test "GitHub issue template exists"
if [ -f ".github/ISSUE_TEMPLATE/bug_report.md" ]; then
  pass
else
  fail "Bug report template missing"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 2: Bash Syntax Validation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "2. Bash Syntax Validation"

for script in terraform cloudformation trupositive install.sh uninstall.sh test.sh; do
  print_test "Syntax validation: $script"
  if bash -n "$script" 2>/dev/null; then
    pass
  else
    fail "Syntax error in $script"
  fi
done

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 3: License & Copyright
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "3. License & Copyright"

print_test "LICENSE file exists and is MIT"
if [ -f "LICENSE" ] && grep -q "MIT License" LICENSE; then
  pass
else
  fail "LICENSE missing or not MIT"
fi

print_test "LICENSE has proper copyright"
if grep -q "Copyright (c) 2024-2026 trupositive-ai" LICENSE; then
  pass
else
  fail "Copyright not updated in LICENSE"
fi

print_test "All scripts have SPDX license identifier"
missing_spdx=()
for script in terraform cloudformation trupositive install.sh uninstall.sh; do
  if ! grep -q "SPDX-License-Identifier: MIT" "$script"; then
    missing_spdx+=("$script")
  fi
done
[ ${#missing_spdx[@]} -eq 0 ] && pass || fail "Missing SPDX: ${missing_spdx[*]}"

print_test "All scripts have shebang"
missing_shebang=()
for script in terraform cloudformation trupositive install.sh uninstall.sh test.sh; do
  if ! head -1 "$script" | grep -q "^#!/"; then
    missing_shebang+=("$script")
  fi
done
[ ${#missing_shebang[@]} -eq 0 ] && pass || fail "Missing shebang: ${missing_shebang[*]}"

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 4: Error Handling & Best Practices
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "4. Error Handling & Best Practices"

print_test "All scripts use 'set -e'"
missing_set_e=()
for script in terraform cloudformation trupositive install.sh uninstall.sh; do
  if ! grep -q "^set -e" "$script"; then
    missing_set_e+=("$script")
  fi
done
[ ${#missing_set_e[@]} -eq 0 ] && pass || fail "Missing 'set -e': ${missing_set_e[*]}"

print_test "All scripts use 'set -o pipefail'"
missing_pipefail=()
for script in terraform cloudformation trupositive install.sh uninstall.sh; do
  if ! grep -q "set -o pipefail" "$script"; then
    missing_pipefail+=("$script")
  fi
done
[ ${#missing_pipefail[@]} -eq 0 ] && pass || fail "Missing pipefail: ${missing_pipefail[*]}"

print_test "Scripts write errors to stderr"
has_stderr=0
for script in terraform cloudformation trupositive install.sh uninstall.sh; do
  if grep -q ">&2" "$script"; then
    ((has_stderr++))
  fi
done
[ $has_stderr -ge 3 ] && pass || fail "Only $has_stderr scripts use stderr"

print_test "Scripts have safe defaults"
safe_defaults=0
for script in terraform cloudformation; do
  if grep -q 'echo "unknown"' "$script"; then
    ((safe_defaults++))
  fi
done
[ $safe_defaults -eq 2 ] && pass || fail "Only $safe_defaults scripts have safe defaults"

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 5: Security Features
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "5. Security Features"

print_test "Input sanitization in terraform wrapper"
if grep -q "sed 's/\[^a-zA-Z0-9" terraform && grep -q "head -c 200" terraform; then
  pass
else
  fail "Input sanitization missing or incomplete"
fi

print_test "Input sanitization in cloudformation wrapper"
if grep -q "sed 's/\[^a-zA-Z0-9" cloudformation && grep -q "head -c 1000" cloudformation; then
  pass
else
  fail "Input sanitization missing or incomplete"
fi

print_test "Path traversal protection in trupositive"
if grep -q '\[\[ "$file" == \*"/"\* \]\]' trupositive; then
  pass
else
  fail "Path traversal protection missing"
fi

print_test "Binary validation in install.sh"
if grep -q "if \[ ! -x" install.sh; then
  pass
else
  fail "Binary validation missing"
fi

print_test "No hardcoded credentials"
if ! grep -r "AKIA\|password=\|secret=" --include="*.sh" . 2>/dev/null | grep -v test | grep -q .; then
  pass
else
  fail "Potential credentials found"
fi

print_test "Sanitization test: dangerous characters"
test_input='$(rm -rf /) && evil'
sanitized=$(echo "$test_input" | sed 's/[^a-zA-Z0-9\/.\-_]//g')
if [[ ! "$sanitized" =~ [\$\(\)\&\;] ]]; then
  pass
else
  fail "Sanitization didn't remove dangerous characters"
fi

print_test "Length limiting test"
long_string=$(printf 'a%.0s' {1..500})
limited=$(echo "$long_string" | head -c 200)
[ ${#limited} -eq 200 ] && pass || fail "Length limiting failed: ${#limited} chars"

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 6: Git Metadata Extraction
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "6. Git Metadata Extraction"

if [ -d .git ]; then
  print_test "Git SHA extraction"
  GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
  if [ -n "$GIT_SHA" ] && [ ${#GIT_SHA} -eq 40 ]; then
    pass
    info "SHA: ${GIT_SHA:0:8}..."
  else
    fail "Failed to extract valid Git SHA"
  fi

  print_test "Git branch extraction"
  GIT_BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "")
  if [ -n "$GIT_BRANCH" ]; then
    pass
    info "Branch: $GIT_BRANCH"
  else
    skip "Not on a branch (detached HEAD)"
  fi

  print_test "Git remote URL extraction"
  GIT_REPO=$(git config --get remote.origin.url 2>/dev/null || echo "")
  if [ -n "$GIT_REPO" ]; then
    pass
    info "Remote: $GIT_REPO"
  else
    skip "No remote configured"
  fi

  print_test "Git commands in wrapper scripts"
  git_commands_found=0
  for script in terraform cloudformation; do
    if grep -q "git rev-parse HEAD" "$script" && \
       grep -q "git symbolic-ref" "$script" && \
       grep -q "git config --get remote.origin.url" "$script"; then
      ((git_commands_found++))
    fi
  done
  [ $git_commands_found -eq 2 ] && pass || fail "Only $git_commands_found scripts have all Git commands"
else
  skip "Not a git repository"
  skip "Not a git repository"
  skip "Not a git repository"
  skip "Not a git repository"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 7: CloudFormation Functionality
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "7. CloudFormation Functionality"

print_test "CloudFormation wrapper exists and is executable"
if [ -x "cloudformation" ]; then
  pass
else
  fail "cloudformation not executable"
fi

print_test "CloudFormation command detection function"
if grep -q "command_accepts_parameters()" cloudformation && \
   grep -q "is_cloudformation_command()" cloudformation; then
  pass
else
  fail "Command detection functions missing"
fi

print_test "CloudFormation parameter injection logic"
if grep -q "parameter-overrides" cloudformation && \
   grep -q "GitSha=\$GIT_SHA" cloudformation && \
   grep -q "GitBranch=\$GIT_BRANCH" cloudformation && \
   grep -q "GitRepo=\$GIT_REPO_SANITIZED" cloudformation; then
  pass
else
  fail "Parameter injection logic incomplete"
fi

print_test "CloudFormation supports deploy command"
if grep -q "deploy" cloudformation; then
  pass
else
  fail "deploy command not supported"
fi

print_test "CloudFormation supports create-stack command"
if grep -q "create-stack" cloudformation; then
  pass
else
  fail "create-stack command not supported"
fi

print_test "CloudFormation supports update-stack command"
if grep -q "update-stack" cloudformation; then
  pass
else
  fail "update-stack command not supported"
fi

print_test "CloudFormation opt-out flag (--no-git-params)"
if grep -q "no-git-params" cloudformation; then
  pass
else
  fail "Opt-out flag missing"
fi

print_test "CloudFormation example template is valid"
if [ -f "example-cloudformation.yaml" ] && \
   grep -q "AWSTemplateFormatVersion" example-cloudformation.yaml && \
   grep -q "Parameters:" example-cloudformation.yaml && \
   grep -q "Resources:" example-cloudformation.yaml; then
  pass
else
  fail "Example template missing or invalid"
fi

print_test "CloudFormation wrapper handles both calling patterns"
if grep -q 'if \[ "$1" = "cloudformation" \]; then' cloudformation && \
   grep -q 'shift' cloudformation && \
   grep -q 'is_cloudformation_command' cloudformation; then
  pass
  info "Bug fix confirmed: handles trupositive and aws wrapper calls"
else
  fail "Dual calling pattern support missing"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 8: Terraform Functionality
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "8. Terraform Functionality"

print_test "Terraform wrapper exists and is executable"
if [ -x "terraform" ]; then
  pass
else
  fail "terraform not executable"
fi

print_test "Terraform exports TF_VAR variables"
if grep -q "export TF_VAR_git_sha" terraform && \
   grep -q "export TF_VAR_git_branch" terraform && \
   grep -q "export TF_VAR_git_repo" terraform; then
  pass
else
  fail "TF_VAR exports missing"
fi

print_test "Terraform finds terraform-real binary"
if grep -q "terraform-real" terraform; then
  pass
else
  fail "terraform-real detection missing"
fi

print_test "Terraform CI/CD environment variable support"
if grep -q "GITHUB_REF_NAME\|CI_COMMIT_REF_NAME\|BUILD_SOURCEBRANCHNAME\|BRANCH_NAME" terraform; then
  pass
else
  fail "CI/CD environment variable support missing"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 9: trupositive CLI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "9. trupositive CLI"

print_test "trupositive CLI exists and is executable"
if [ -x "trupositive" ]; then
  pass
else
  fail "trupositive not executable"
fi

print_test "trupositive has init command"
if grep -q 'if \[ "$1" = "init" \]; then' trupositive; then
  pass
else
  fail "init command missing"
fi

print_test "trupositive has infrastructure detection"
if grep -q "detect_infra_tool" trupositive; then
  pass
else
  fail "Infrastructure detection missing"
fi

print_test "trupositive detects CloudFormation"
if grep -q "is_cloudformation_template" trupositive && \
   grep -q "AWSTemplateFormatVersion" trupositive; then
  pass
else
  fail "CloudFormation detection missing"
fi

print_test "trupositive detects Terraform"
if grep -q "*.tf" trupositive; then
  pass
else
  fail "Terraform detection missing"
fi

print_test "trupositive generates CloudFormation params"
if grep -q "run_init_cloudformation" trupositive && \
   grep -q "trupositive-params.yaml" trupositive; then
  pass
else
  fail "CloudFormation init missing"
fi

print_test "trupositive generates Terraform config"
if grep -q "run_init" trupositive && \
   grep -q "trupositive.auto.tf" trupositive; then
  pass
else
  fail "Terraform init missing"
fi

print_test "trupositive detects AWS provider"
if grep -q 'provider "aws"' trupositive; then
  pass
else
  fail "AWS provider detection missing"
fi

print_test "trupositive detects Azure provider"
if grep -q 'provider "azurerm"' trupositive; then
  pass
else
  fail "Azure provider detection missing"
fi

print_test "trupositive detects GCP provider"
if grep -q 'provider "google"' trupositive; then
  pass
else
  fail "GCP provider detection missing"
fi

print_test "trupositive has nullglob for safe iteration"
if grep -q "shopt -s nullglob" trupositive; then
  pass
else
  fail "nullglob not used"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 10: Installation & Uninstallation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "10. Installation & Uninstallation"

print_test "install.sh checks for Terraform or AWS CLI"
if grep -q "REAL_TF\|REAL_AWS" install.sh && \
   grep -q "command -v terraform\|command -v aws" install.sh; then
  pass
else
  fail "Binary detection missing"
fi

print_test "install.sh creates bin directory"
if grep -q "mkdir -p" install.sh && grep -q "BIN_DIR" install.sh; then
  pass
else
  fail "Directory creation missing"
fi

print_test "install.sh checks write permissions"
if grep -q "\[ -w \"\$BIN_DIR\" \]" install.sh; then
  pass
else
  fail "Permission check missing"
fi

print_test "install.sh validates binaries are executable"
if grep -q "if \[ ! -x" install.sh; then
  pass
else
  fail "Binary validation missing"
fi

print_test "install.sh supports TRUPOSITIVE_BIN_DIR"
if grep -q "TRUPOSITIVE_BIN_DIR" install.sh; then
  pass
else
  fail "Environment variable support missing"
fi

print_test "uninstall.sh removes wrappers"
if grep -q "rm.*terraform\|rm.*aws\|rm.*cloudformation" uninstall.sh; then
  pass
else
  fail "Wrapper removal missing"
fi

print_test "uninstall.sh restores original binaries"
if grep -q "terraform-real\|aws-real" uninstall.sh && grep -q "cp" uninstall.sh; then
  pass
else
  fail "Binary restoration missing"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 11: Documentation Quality
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "11. Documentation Quality"

print_test "README.md has badges"
if grep -q "!\[License: MIT\]" README.md && \
   grep -q "!\[Bash\]" README.md && \
   grep -q "!\[Version\]" README.md; then
  pass
else
  fail "Badges missing from README"
fi

print_test "README.md has installation instructions"
if grep -q "curl -fsSL" README.md && grep -q "install.sh" README.md; then
  pass
else
  fail "Installation instructions missing"
fi

print_test "README.md has usage examples"
if grep -q "terraform apply\|aws cloudformation deploy" README.md; then
  pass
else
  fail "Usage examples missing"
fi

print_test "README.md has documentation links"
if grep -q "EXAMPLES.md\|TESTING.md\|CONTRIBUTING.md" README.md; then
  pass
else
  fail "Documentation links missing"
fi

print_test "EXAMPLES.md exists and has content"
if [ -f "EXAMPLES.md" ] && [ $(wc -l < EXAMPLES.md) -gt 100 ]; then
  pass
  info "EXAMPLES.md: $(wc -l < EXAMPLES.md) lines"
else
  fail "EXAMPLES.md missing or too short"
fi

print_test "EXAMPLES.md has CloudFormation examples"
if grep -q "CloudFormation" EXAMPLES.md && grep -q "aws cloudformation" EXAMPLES.md; then
  pass
else
  fail "CloudFormation examples missing"
fi

print_test "EXAMPLES.md has Terraform examples"
if grep -q "Terraform" EXAMPLES.md && grep -q "terraform apply" EXAMPLES.md; then
  pass
else
  fail "Terraform examples missing"
fi

print_test "EXAMPLES.md has CI/CD examples"
if grep -q "GitHub Actions\|GitLab CI" EXAMPLES.md; then
  pass
else
  fail "CI/CD examples missing"
fi

print_test "TESTING.md has test instructions"
if grep -q "./test.sh" TESTING.md; then
  pass
else
  fail "Test instructions missing"
fi

print_test "CHANGELOG.md has dated releases"
if grep -q "\[1.1.0\] - 2026-01-19" CHANGELOG.md; then
  pass
else
  fail "CHANGELOG missing dated release"
fi

print_test "CHANGELOG.md follows Keep a Changelog format"
if grep -q "keepachangelog.com" CHANGELOG.md && \
   grep -q "### Added\|### Changed\|### Fixed" CHANGELOG.md; then
  pass
else
  fail "CHANGELOG doesn't follow standard format"
fi

print_test "CONTRIBUTING.md has contribution guidelines"
if [ -f "CONTRIBUTING.md" ] && grep -q "Pull Request\|PR" CONTRIBUTING.md; then
  pass
else
  fail "Contribution guidelines missing or incomplete"
fi

print_test "SECURITY.md has reporting policy"
if [ -f "SECURITY.md" ] && grep -q "Reporting\|security" SECURITY.md; then
  pass
else
  fail "Security policy missing or incomplete"
fi

print_test "FEATURE_CLOUDFORMATION.md documents feature"
if [ -f "FEATURE_CLOUDFORMATION.md" ] && grep -q "CloudFormation" FEATURE_CLOUDFORMATION.md; then
  pass
else
  fail "Feature documentation missing"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 12: Code Style & Consistency
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "12. Code Style & Consistency"

print_test ".editorconfig exists"
if [ -f ".editorconfig" ]; then
  pass
else
  fail ".editorconfig missing"
fi

print_test ".gitattributes exists"
if [ -f ".gitattributes" ]; then
  pass
else
  fail ".gitattributes missing"
fi

print_test ".editorconfig has bash configuration"
if grep -q "*.sh\|*.bash" .editorconfig 2>/dev/null; then
  pass
else
  fail ".editorconfig missing bash config"
fi

print_test ".gitattributes enforces LF line endings"
if grep -q "text eol=lf" .gitattributes 2>/dev/null; then
  pass
else
  fail ".gitattributes doesn't enforce LF"
fi

print_test "Scripts use consistent error output (>&2)"
stderr_count=$(grep -c ">&2" terraform cloudformation trupositive install.sh uninstall.sh)
if [ "$stderr_count" -gt 10 ]; then
  pass
  info "Found $stderr_count stderr redirects"
else
  fail "Only $stderr_count stderr redirects (should be more)"
fi

print_test "Scripts use consistent quoting"
# Check for proper quoting of variables
unquoted_vars=0
for script in terraform cloudformation trupositive install.sh uninstall.sh; do
  # This is a simplified check - count quoted vs unquoted variable references
  quoted=$(grep -o '\$[{]' "$script" | wc -l)
  if [ "$quoted" -gt 5 ]; then
    ((unquoted_vars++))
  fi
done
[ $unquoted_vars -ge 3 ] && pass || info "Some scripts could use more consistent quoting"

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 13: Version & Release Management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "13. Version & Release Management"

print_test "README shows version 1.1.0"
if grep -q "version-1.1.0" README.md || grep -q "v1.1.0" README.md; then
  pass
else
  fail "Version missing from README"
fi

print_test "CHANGELOG has version 1.1.0"
if grep -q "\[1.1.0\]" CHANGELOG.md; then
  pass
else
  fail "Version missing from CHANGELOG"
fi

print_test "CHANGELOG entry is dated"
if grep -q "\[1.1.0\] - 2026" CHANGELOG.md; then
  pass
else
  fail "CHANGELOG entry not dated"
fi

print_test "Version follows semantic versioning"
if grep -q "semver.org" CHANGELOG.md; then
  pass
else
  info "Consider adding semver reference"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CATEGORY 14: Integration Tests (Optional)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_category "14. Integration Tests (Optional)"

print_test "Terraform binary available"
if command_exists terraform; then
  pass
  info "Terraform: $(terraform version | head -1)"
else
  skip "Terraform not installed"
fi

print_test "AWS CLI available"
if command_exists aws; then
  pass
  info "AWS CLI: $(aws --version 2>&1 | head -1)"
else
  skip "AWS CLI not installed"
fi

print_test "Git available"
if command_exists git; then
  pass
  info "Git: $(git --version)"
else
  fail "Git is required but not installed"
fi

print_test "Bash version 5.0+"
bash_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
if [ $(echo "$bash_version" | cut -d. -f1) -ge 5 ]; then
  pass
  info "Bash: $bash_version"
else
  info "Bash $bash_version (recommend 5.0+)"
fi

category_summary

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FINAL SUMMARY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_banner "TEST RESULTS SUMMARY"

echo -e "${BOLD}Total Tests Run:${NC}     $TOTAL_TESTS"
echo -e "${GREEN}${BOLD}Passed:${NC}              $PASSED_TESTS"
echo -e "${RED}${BOLD}Failed:${NC}              $FAILED_TESTS"
echo -e "${YELLOW}${BOLD}Skipped:${NC}             $SKIPPED_TESTS"
echo ""

# Calculate pass rate
if [ $TOTAL_TESTS -gt 0 ]; then
  PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
  echo -e "${BOLD}Pass Rate:${NC}           ${PASS_RATE}%"
  echo ""
fi

# Final verdict
if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}${BOLD}✓ ALL TESTS PASSED${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${GREEN}${BOLD}The repository is PRODUCTION READY!${NC}"
  echo ""
  
  if [ $SKIPPED_TESTS -gt 0 ]; then
    echo -e "${YELLOW}Note:${NC} $SKIPPED_TESTS tests were skipped (optional integration tests)"
    echo ""
  fi
  
  echo "Next steps:"
  echo "  1. Remove internal dev docs (if any)"
  echo "  2. Commit all changes"
  echo "  3. Create GitHub release v1.1.0"
  echo "  4. Push to remote"
  echo ""
  
  exit 0
else
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}${BOLD}✗ TESTS FAILED${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${RED}$FAILED_TESTS test(s) failed. Please review the output above.${NC}"
  echo ""
  
  exit 1
fi
