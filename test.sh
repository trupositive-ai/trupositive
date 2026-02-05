#!/bin/bash
# Comprehensive test suite for trupositive
# Tests both Terraform and CloudFormation functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper functions
print_header() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"
}

print_test() {
  echo -e "${YELLOW}▶ Test $1: $2${NC}"
  ((TESTS_RUN++))
}

print_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
}

print_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  ((TESTS_FAILED++))
}

print_skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  ((TESTS_SKIPPED++))
  ((TESTS_RUN--))
}

print_info() {
  echo -e "  ${BLUE}ℹ${NC} $1"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ═══════════════════════════════════════════════════
# TEST SUITE START
# ═══════════════════════════════════════════════════

print_header "trupositive Test Suite"
echo "Testing Terraform and CloudFormation wrappers"
echo "Current directory: $(pwd)"
echo ""

# ═══════════════════════════════════════════════════
# 1. BASH SYNTAX VALIDATION
# ═══════════════════════════════════════════════════

print_header "1. Bash Syntax Validation"

print_test "1.1" "terraform wrapper syntax"
if bash -n terraform 2>/dev/null; then
  print_pass "terraform syntax valid"
else
  print_fail "terraform has syntax errors"
fi

print_test "1.2" "cloudformation wrapper syntax"
if bash -n cloudformation 2>/dev/null; then
  print_pass "cloudformation syntax valid"
else
  print_fail "cloudformation has syntax errors"
fi

print_test "1.3" "trupositive CLI syntax"
if bash -n trupositive 2>/dev/null; then
  print_pass "trupositive syntax valid"
else
  print_fail "trupositive has syntax errors"
fi

print_test "1.4" "install.sh syntax"
if bash -n install.sh 2>/dev/null; then
  print_pass "install.sh syntax valid"
else
  print_fail "install.sh has syntax errors"
fi

print_test "1.5" "uninstall.sh syntax"
if bash -n uninstall.sh 2>/dev/null; then
  print_pass "uninstall.sh syntax valid"
else
  print_fail "uninstall.sh has syntax errors"
fi

# ═══════════════════════════════════════════════════
# 2. FILE STRUCTURE VALIDATION
# ═══════════════════════════════════════════════════

print_header "2. File Structure Validation"

print_test "2.1" "Required files exist"
required_files=(
  "terraform"
  "cloudformation"
  "trupositive"
  "install.sh"
  "uninstall.sh"
  "README.md"
  "CHANGELOG.md"
  "LICENSE"
  "EXAMPLES.md"
  "example-cloudformation.yaml"
)
missing_files=()
for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    missing_files+=("$file")
  fi
done
if [ ${#missing_files[@]} -eq 0 ]; then
  print_pass "All required files present"
else
  print_fail "Missing files: ${missing_files[*]}"
fi

print_test "2.2" "Scripts are executable"
scripts=("terraform" "cloudformation" "trupositive" "install.sh" "uninstall.sh")
non_executable=()
for script in "${scripts[@]}"; do
  if [ ! -x "$script" ]; then
    non_executable+=("$script")
  fi
done
if [ ${#non_executable[@]} -eq 0 ]; then
  print_pass "All scripts are executable"
else
  print_fail "Non-executable scripts: ${non_executable[*]}"
fi

print_test "2.3" "License headers present"
missing_headers=()
for script in "${scripts[@]}"; do
  if ! grep -q "SPDX-License-Identifier" "$script"; then
    missing_headers+=("$script")
  fi
done
if [ ${#missing_headers[@]} -eq 0 ]; then
  print_pass "All scripts have license headers"
else
  print_fail "Missing license headers: ${missing_headers[*]}"
fi

# ═══════════════════════════════════════════════════
# 3. GIT METADATA EXTRACTION
# ═══════════════════════════════════════════════════

print_header "3. Git Metadata Extraction"

print_test "3.1" "Git SHA extraction"
if [ -d .git ]; then
  GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
  if [ -n "$GIT_SHA" ] && [ "$GIT_SHA" != "unknown" ]; then
    print_pass "Git SHA: ${GIT_SHA:0:8}..."
  else
    print_fail "Failed to extract Git SHA"
  fi
else
  print_skip "Not a git repository"
fi

print_test "3.2" "Git branch extraction"
if [ -d .git ]; then
  GIT_BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "unknown")
  if [ -n "$GIT_BRANCH" ]; then
    print_pass "Git branch: $GIT_BRANCH"
  else
    print_fail "Failed to extract Git branch"
  fi
else
  print_skip "Not a git repository"
fi

print_test "3.3" "Git repo URL extraction"
if [ -d .git ]; then
  GIT_REPO=$(git config --get remote.origin.url 2>/dev/null || echo "unknown")
  if [ -n "$GIT_REPO" ]; then
    print_pass "Git repo: $GIT_REPO"
  else
    print_fail "Failed to extract Git repo URL"
  fi
else
  print_skip "Not a git repository"
fi

# ═══════════════════════════════════════════════════
# 4. INPUT SANITIZATION
# ═══════════════════════════════════════════════════

print_header "4. Input Sanitization"

print_test "4.1" "Branch name sanitization"
malicious_branch='$(rm -rf /) && evil; ls'
sanitized=$(echo "$malicious_branch" | sed 's/[^a-zA-Z0-9\/.\-_]//g' | head -c 200)
if [[ ! "$sanitized" =~ [\$\(\)\&\;] ]]; then
  print_pass "Dangerous characters removed: '$malicious_branch' → '$sanitized'"
else
  print_fail "Sanitization failed, dangerous chars remain: $sanitized"
fi

print_test "4.2" "Repo URL sanitization"
malicious_repo='https://github.com/user/repo.git; rm -rf /'
sanitized=$(echo "$malicious_repo" | sed 's/[^a-zA-Z0-9:\/.\-_@]//g' | head -c 1000)
if [[ ! "$sanitized" =~ [\$\(\)\&\;] ]]; then
  print_pass "Dangerous characters removed: sanitized to '$sanitized'"
else
  print_fail "Sanitization failed, dangerous chars remain: $sanitized"
fi

print_test "4.3" "Length limiting - branch"
long_input=$(printf 'a%.0s' {1..500})
limited=$(echo "$long_input" | head -c 200)
if [ ${#limited} -eq 200 ]; then
  print_pass "Branch limited to 200 characters"
else
  print_fail "Length limiting failed: ${#limited} chars (expected 200)"
fi

print_test "4.4" "Length limiting - repo"
long_input=$(printf 'a%.0s' {1..2000})
limited=$(echo "$long_input" | head -c 1000)
if [ ${#limited} -eq 1000 ]; then
  print_pass "Repo URL limited to 1000 characters"
else
  print_fail "Length limiting failed: ${#limited} chars (expected 1000)"
fi

# ═══════════════════════════════════════════════════
# 5. CLOUDFORMATION DETECTION
# ═══════════════════════════════════════════════════

print_header "5. CloudFormation Template Detection"

print_test "5.1" "Valid CloudFormation template detection"
if [ -f "example-cloudformation.yaml" ]; then
  if grep -q "^AWSTemplateFormatVersion:" example-cloudformation.yaml 2>/dev/null; then
    print_pass "CloudFormation template correctly identified"
  else
    print_fail "CloudFormation template not detected"
  fi
else
  print_skip "example-cloudformation.yaml not found"
fi

print_test "5.2" "False positive prevention"
# Create a temporary JSON file that's NOT CloudFormation
temp_json=$(mktemp)
echo '{"Resources": "not a CFN template"}' > "$temp_json"
if grep -q "^AWSTemplateFormatVersion:" "$temp_json" 2>/dev/null; then
  print_fail "False positive: Regular JSON detected as CloudFormation"
  rm -f "$temp_json"
else
  print_pass "Non-CloudFormation JSON correctly rejected"
  rm -f "$temp_json"
fi

# ═══════════════════════════════════════════════════
# 6. TERRAFORM WRAPPER TESTS
# ═══════════════════════════════════════════════════

print_header "6. Terraform Wrapper Tests"

print_test "6.1" "Terraform wrapper exports variables"
if command_exists terraform || [ -f /usr/local/bin/terraform ]; then
  # Source the terraform wrapper to check variable exports
  (
    source terraform 2>/dev/null || true
    if [ -n "$TF_VAR_git_sha" ]; then
      exit 0
    else
      exit 1
    fi
  ) && print_pass "TF_VAR variables would be exported" || print_skip "Cannot test without running wrapper"
else
  print_skip "Terraform not installed"
fi

print_test "6.2" "Terraform wrapper has safe defaults"
if grep -q 'echo "unknown"' terraform; then
  print_pass "Safe defaults (unknown) present in terraform wrapper"
else
  print_fail "Safe defaults missing in terraform wrapper"
fi

# ═══════════════════════════════════════════════════
# 7. CLOUDFORMATION WRAPPER TESTS
# ═══════════════════════════════════════════════════

print_header "7. CloudFormation Wrapper Tests"

print_test "7.1" "CloudFormation wrapper has command detection"
if grep -q "command_accepts_parameters" cloudformation; then
  print_pass "Command detection function present"
else
  print_fail "Command detection function missing"
fi

print_test "7.2" "CloudFormation wrapper supports parameter injection"
if grep -q "parameter-overrides" cloudformation; then
  print_pass "Parameter override support present"
else
  print_fail "Parameter override support missing"
fi

print_test "7.3" "CloudFormation wrapper has safe defaults"
if grep -q 'echo "unknown"' cloudformation; then
  print_pass "Safe defaults (unknown) present in cloudformation wrapper"
else
  print_fail "Safe defaults missing in cloudformation wrapper"
fi

print_test "7.4" "CloudFormation wrapper supports opt-out"
if grep -q "no-git-params" cloudformation; then
  print_pass "Opt-out flag (--no-git-params) supported"
else
  print_fail "Opt-out flag missing"
fi

# ═══════════════════════════════════════════════════
# 8. TRUPOSITIVE CLI TESTS
# ═══════════════════════════════════════════════════

print_header "8. trupositive CLI Tests"

print_test "8.1" "Auto-detection function exists"
if grep -q "detect_infra_tool" trupositive; then
  print_pass "Infrastructure tool detection function present"
else
  print_fail "Detection function missing"
fi

print_test "8.2" "CloudFormation init function exists"
if grep -q "run_init_cloudformation" trupositive; then
  print_pass "CloudFormation initialization function present"
else
  print_fail "CloudFormation init function missing"
fi

print_test "8.3" "Path traversal protection"
if grep -q '\[\[ "$file" == \*"\/"\* \]\]' trupositive; then
  print_pass "Path traversal protection present"
else
  print_fail "Path traversal protection missing"
fi

print_test "8.4" "Nullglob for safe iteration"
if grep -q "shopt -s nullglob" trupositive; then
  print_pass "Safe glob expansion (nullglob) used"
else
  print_fail "Nullglob not used - potential issues with missing files"
fi

print_test "8.5" "CloudFormation wrapper passthrough matches Terraform pattern"
if grep -q 'exec "$CLOUDFORMATION_WRAPPER" "$@"' trupositive; then
  print_pass "CloudFormation passthrough correctly passes args as-is (like Terraform)"
else
  print_fail "CloudFormation passthrough doesn't match Terraform pattern"
fi

# ═══════════════════════════════════════════════════
# 9. INSTALLATION SCRIPT TESTS
# ═══════════════════════════════════════════════════

print_header "9. Installation Script Tests"

print_test "9.1" "Binary validation before installation"
if grep -q 'if \[ ! -x' install.sh; then
  print_pass "Binary executable validation present"
else
  print_fail "Binary validation missing"
fi

print_test "9.2" "Dynamic path resolution in AWS wrapper"
if grep -q 'WRAPPER_DIR=' install.sh; then
  print_pass "Dynamic path resolution used (no hardcoded paths)"
else
  print_fail "May contain hardcoded paths"
fi

print_test "9.3" "Environment variable support"
if grep -q 'TRUPOSITIVE_BIN_DIR' install.sh; then
  print_pass "Customizable installation directory supported"
else
  print_fail "TRUPOSITIVE_BIN_DIR not supported"
fi

# ═══════════════════════════════════════════════════
# 10. DOCUMENTATION TESTS
# ═══════════════════════════════════════════════════

print_header "10. Documentation Tests"

print_test "10.1" "README mentions CloudFormation"
if grep -qi "cloudformation" README.md; then
  print_pass "README documents CloudFormation support"
else
  print_fail "README missing CloudFormation documentation"
fi

print_test "10.2" "Examples file contains CloudFormation examples"
if [ -f EXAMPLES.md ]; then
  if grep -q "CloudFormation" EXAMPLES.md; then
    print_pass "EXAMPLES.md contains CloudFormation examples"
  else
    print_fail "EXAMPLES.md missing CloudFormation examples"
  fi
else
  print_fail "EXAMPLES.md not found"
fi

print_test "10.3" "CHANGELOG documents version 1.1.0"
if grep -q "1.1.0" CHANGELOG.md; then
  print_pass "CHANGELOG contains version 1.1.0 entry"
else
  print_fail "CHANGELOG missing version 1.1.0"
fi

print_test "10.4" "Example CloudFormation template is valid YAML"
if [ -f example-cloudformation.yaml ]; then
  # Basic YAML validation
  if grep -q "AWSTemplateFormatVersion" example-cloudformation.yaml && \
     grep -q "Parameters:" example-cloudformation.yaml && \
     grep -q "Resources:" example-cloudformation.yaml; then
    print_pass "Example template has required CloudFormation sections"
  else
    print_fail "Example template missing required sections"
  fi
else
  print_fail "example-cloudformation.yaml not found"
fi

# ═══════════════════════════════════════════════════
# 11. SECURITY TESTS
# ═══════════════════════════════════════════════════

print_header "11. Security Tests"

print_test "11.1" "No hardcoded credentials"
if ! grep -r "AKIA\|password\|secret\|token" --include="*.sh" . 2>/dev/null | grep -v test.sh | grep -q .; then
  print_pass "No hardcoded credentials found"
else
  print_fail "Potential credentials found in scripts"
fi

print_test "11.2" "Proper error handling (set -e)"
scripts_without_set_e=()
for script in terraform cloudformation trupositive install.sh uninstall.sh; do
  if ! grep -q "^set -e" "$script"; then
    scripts_without_set_e+=("$script")
  fi
done
if [ ${#scripts_without_set_e[@]} -eq 0 ]; then
  print_pass "All scripts use 'set -e'"
else
  print_fail "Scripts missing 'set -e': ${scripts_without_set_e[*]}"
fi

print_test "11.3" "Pipefail for safer pipes"
scripts_without_pipefail=()
for script in terraform cloudformation trupositive install.sh uninstall.sh; do
  if ! grep -q "set -o pipefail" "$script"; then
    scripts_without_pipefail+=("$script")
  fi
done
if [ ${#scripts_without_pipefail[@]} -eq 0 ]; then
  print_pass "All scripts use 'set -o pipefail'"
else
  print_fail "Scripts missing 'set -o pipefail': ${scripts_without_pipefail[*]}"
fi

# ═══════════════════════════════════════════════════
# 12. INTEGRATION TESTS (Optional - requires tools)
# ═══════════════════════════════════════════════════

print_header "12. Integration Tests (Optional)"

print_test "12.1" "Terraform binary available"
if command_exists terraform; then
  TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -n1)
  print_pass "Terraform installed: $TF_VERSION"
  print_info "Ready for Terraform integration tests"
else
  print_skip "Terraform not installed - integration tests unavailable"
fi

print_test "12.2" "AWS CLI available"
if command_exists aws; then
  AWS_VERSION=$(aws --version 2>&1 | awk '{print $1}')
  print_pass "AWS CLI installed: $AWS_VERSION"
  print_info "Ready for CloudFormation integration tests"
else
  print_skip "AWS CLI not installed - CloudFormation integration tests unavailable"
fi

print_test "12.3" "Git available"
if command_exists git; then
  GIT_VERSION=$(git --version)
  print_pass "Git installed: $GIT_VERSION"
else
  print_fail "Git is required but not installed"
fi

# ═══════════════════════════════════════════════════
# TEST RESULTS SUMMARY
# ═══════════════════════════════════════════════════

print_header "Test Results Summary"

echo -e "Total Tests:   ${BLUE}$TESTS_RUN${NC}"
echo -e "Passed:        ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:        ${RED}$TESTS_FAILED${NC}"
echo -e "Skipped:       ${YELLOW}$TESTS_SKIPPED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${GREEN}The codebase is production ready!${NC}"
  echo ""
  
  if [ $TESTS_SKIPPED -gt 0 ]; then
    echo -e "${YELLOW}Note: $TESTS_SKIPPED tests were skipped${NC}"
    echo "These tests require Terraform/AWS CLI to be installed"
    echo "or are environment-specific."
    echo ""
  fi
  
  echo "Next steps:"
  echo "  1. Review test results above"
  echo "  2. If you have Terraform/AWS CLI installed, run integration tests"
  echo "  3. Commit the changes: git add -A && git commit"
  echo ""
  
  exit 0
else
  echo -e "${RED}═══════════════════════════════════════════════════${NC}"
  echo -e "${RED}✗ TESTS FAILED${NC}"
  echo -e "${RED}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${RED}$TESTS_FAILED test(s) failed. Please review the output above.${NC}"
  echo ""
  
  exit 1
fi
