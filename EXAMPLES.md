# trupositive Examples

Complete usage examples for both Terraform and CloudFormation workflows.

## Quick Start

### CloudFormation
```bash
cd your-cloudformation-project
trupositive init
aws cloudformation deploy --template-file template.yaml --stack-name my-stack
```

### Terraform
```bash
cd your-terraform-project
trupositive init
terraform apply
```

---

## CloudFormation Examples

### 1. Initialize trupositive in your CloudFormation project

```bash
cd your-cloudformation-project
trupositive init
```

This creates `trupositive-params.yaml` with parameter definitions and usage examples.

### 2. Add parameters to your CloudFormation template

See [example-cloudformation.yaml](example-cloudformation.yaml) for a complete working template.

Basic structure:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Example template with Git metadata

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

### 3. Deploy using AWS CLI

The wrapper automatically injects Git metadata:

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-stack
```

The Git parameters (GitSha, GitBranch, GitRepo) are automatically passed via `--parameter-overrides`.

### 4. Verify the tags

```bash
aws cloudformation describe-stacks --stack-name my-stack
```

### 5. Multiple Resources Example

```yaml
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
          
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-12345678
      InstanceType: t2.micro
      Tags:
        - Key: Name
          Value: MyInstance
        - Key: git_sha
          Value: !Ref GitSha
        - Key: git_branch
          Value: !Ref GitBranch
        - Key: git_repo
          Value: !Ref GitRepo
```

---

## Terraform Examples

### 1. Initialize trupositive in your Terraform project

```bash
cd your-terraform-project
trupositive init
```

This creates `trupositive.auto.tf` with variable definitions and provider configuration.

### 2. Use Terraform normally

```bash
terraform init
terraform plan
terraform apply
```

### 3. For AWS (automatic tagging)

The generated `trupositive.auto.tf` includes:

```hcl
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

All AWS resources automatically get these tags!

### 4. For Azure/GCP (manual tagging)

The generated `trupositive.auto.tf` includes a `locals` block. Add tags to individual resources:

**Azure:**
```hcl
resource "azurerm_storage_account" "example" {
  name                     = "example"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = local.default_tags  # Git metadata tags
}
```

**GCP:**
```hcl
resource "google_storage_bucket" "example" {
  name     = "example-bucket"
  location = "US"
  
  labels = local.default_labels  # Git metadata labels
}
```

### 5. Multiple AWS Resources Example

```hcl
# trupositive.auto.tf (auto-generated)
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

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      git_sha    = var.git_sha
      git_branch = var.git_branch
      git_repo   = var.git_repo
      managed_by = "terraform"
    }
  }
}

# main.tf (your resources)
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
  # Git tags automatically applied!
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  # Git tags automatically applied!
}
```

All AWS resources automatically inherit the Git metadata tags!

---

## Mixed Projects

If you have both Terraform and CloudFormation in the same repository:

```bash
# For Terraform subdirectory
cd terraform/
trupositive init

# For CloudFormation subdirectory
cd ../cloudformation/
trupositive init
```

The tool automatically detects which infrastructure tool you're using based on file extensions.

---

## CI/CD Examples

trupositive works seamlessly in CI/CD pipelines. It automatically detects branch names from:

- GitHub Actions: `GITHUB_REF_NAME`
- GitLab CI: `CI_COMMIT_REF_NAME`
- Azure DevOps: `BUILD_SOURCEBRANCHNAME`
- Jenkins: `BRANCH_NAME`

No additional configuration needed!

### GitHub Actions Example

```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install trupositive
        run: curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
      
      - name: Deploy CloudFormation
        run: |
          export PATH="$HOME/.local/bin:$PATH"
          aws cloudformation deploy \
            --template-file template.yaml \
            --stack-name my-stack
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### GitLab CI Example

```yaml
deploy:
  image: hashicorp/terraform:latest
  before_script:
    - curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
    - export PATH="$HOME/.local/bin:$PATH"
  script:
    - terraform init
    - terraform apply -auto-approve
```

---

## Advanced Usage

### Disable Git parameter injection (CloudFormation only)

If you want to use AWS CLI without Git parameter injection:

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-stack \
  --no-git-params
```

### Use custom parameter overrides (CloudFormation)

You can combine trupositive parameters with your own:

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-stack \
  --parameter-overrides Environment=prod Region=us-east-1
```

The wrapper will add Git parameters alongside your custom ones.

### Verify injected variables (Terraform)

```bash
terraform console
> var.git_sha
> var.git_branch
> var.git_repo
```

### Override Git metadata manually (for testing)

**Terraform:**
```bash
TF_VAR_git_sha="test-sha" \
TF_VAR_git_branch="test-branch" \
TF_VAR_git_repo="test-repo" \
terraform apply
```

**CloudFormation:**
```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-stack \
  --parameter-overrides GitSha=custom-sha GitBranch=custom-branch GitRepo=custom-repo
```

---

## Complete Working Examples

### CloudFormation
See [example-cloudformation.yaml](example-cloudformation.yaml) for a complete, working CloudFormation template.

### Terraform
Create a test directory:

```bash
mkdir test-terraform && cd test-terraform
git init

cat > main.tf <<'EOF'
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      git_sha    = var.git_sha
      git_branch = var.git_branch
      git_repo   = var.git_repo
    }
  }
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

resource "aws_s3_bucket" "example" {
  bucket = "my-trupositive-example-bucket"
}

output "bucket_name" {
  value = aws_s3_bucket.example.id
}

output "git_metadata" {
  value = {
    sha    = var.git_sha
    branch = var.git_branch
    repo   = var.git_repo
  }
}
EOF

git add .
git commit -m "Initial commit"

terraform init
terraform apply
```

---

## Troubleshooting

### Git metadata shows "unknown"
- Make sure you're in a Git repository: `git status`
- Check you have commits: `git log`
- Verify remote is set: `git remote -v`

### Wrapper not being used
- Check PATH: `echo $PATH | grep .local/bin`
- Verify wrapper location: `which terraform` or `which aws`
- Reinstall if needed: `curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash`

### CloudFormation parameters not injected
- Ensure you're using AWS CLI for CloudFormation commands
- Check wrapper is installed: `which aws`
- Verify command syntax: `aws cloudformation deploy --help`

---

## See Also

- [README.md](README.md) - Installation and basic usage
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contributing guidelines