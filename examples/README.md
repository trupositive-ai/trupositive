# trupositive Examples

Real-world examples showing how to use trupositive with different infrastructure tools and cloud providers.

## Quick Links

- [Terraform + AWS](#terraform--aws)
- [Terraform + Azure](#terraform--azure)
- [Terraform + GCP](#terraform--gcp)
- [CloudFormation](#cloudformation)
- [CI/CD Integration](#cicd-integration)

## Terraform + AWS

### Example 1: S3 Bucket with Automatic Tags

```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  # trupositive automatically provides these variables
  default_tags {
    tags = {
      git_sha    = var.git_sha
      git_branch = var.git_branch
      git_repo   = var.git_repo
      managed_by = "terraform"
    }
  }
}

variable "git_sha" { default = "unknown" }
variable "git_branch" { default = "unknown" }
variable "git_repo" { default = "unknown" }

resource "aws_s3_bucket" "example" {
  bucket = "my-app-bucket-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}
```

**Usage:**
```bash
trupositive init  # Generates trupositive.auto.tf
terraform init
terraform apply
```

See full example: [examples/terraform/aws/](terraform/aws/)

## Terraform + Azure

### Example 2: Resource Group with Tags

```hcl
# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# trupositive generates these variables
variable "git_sha" { default = "unknown" }
variable "git_branch" { default = "unknown" }
variable "git_repo" { default = "unknown" }

locals {
  default_tags = {
    git_sha    = var.git_sha
    git_branch = var.git_branch
    git_repo   = var.git_repo
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "example" {
  name     = "my-app-rg"
  location = "East US"
  tags     = local.default_tags
}

resource "azurerm_storage_account" "example" {
  name                     = "myappstorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.default_tags
}
```

**Note:** Azure requires manual tag application to each resource.

See full example: [examples/terraform/azure/](terraform/azure/)

## Terraform + GCP

### Example 3: GCS Bucket with Labels

```hcl
# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

variable "project_id" { type = string }
variable "git_sha" { default = "unknown" }
variable "git_branch" { default = "unknown" }
variable "git_repo" { default = "unknown" }

locals {
  # GCP uses labels (not tags) and has character restrictions
  default_labels = {
    git_sha    = replace(lower(var.git_sha), "/[^a-z0-9_-]/", "-")
    git_branch = replace(lower(var.git_branch), "/[^a-z0-9_-]/", "-")
    managed_by = "terraform"
  }
}

resource "google_storage_bucket" "example" {
  name     = "${var.project_id}-my-app-bucket"
  location = "US"
  labels   = local.default_labels
}
```

**Note:** GCP labels must be lowercase and have character restrictions.

See full example: [examples/terraform/gcp/](terraform/gcp/)

## CloudFormation

### Example 4: Stack with Git Metadata Parameters

```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Example stack with trupositive Git metadata

Parameters:
  GitSha:
    Type: String
    Default: "unknown"
    Description: Git commit SHA (auto-injected by trupositive)
  
  GitBranch:
    Type: String
    Default: "unknown"
    Description: Git branch (auto-injected by trupositive)
  
  GitRepo:
    Type: String
    Default: "unknown"
    Description: Git repository (auto-injected by trupositive)

Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'my-app-${AWS::AccountId}'
      Tags:
        - Key: git_sha
          Value: !Ref GitSha
        - Key: git_branch
          Value: !Ref GitBranch
        - Key: git_repo
          Value: !Ref GitRepo
        - Key: managed_by
          Value: cloudformation

  MyFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: my-app-function
      Runtime: python3.11
      Handler: index.handler
      Code:
        ZipFile: |
          def handler(event, context):
              return {'statusCode': 200}
      Role: !GetAtt FunctionRole.Arn
      Tags:
        - Key: git_sha
          Value: !Ref GitSha
        - Key: git_branch
          Value: !Ref GitBranch

  FunctionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      Tags:
        - Key: git_sha
          Value: !Ref GitSha

Outputs:
  BucketName:
    Value: !Ref MyBucket
  
  GitMetadata:
    Description: Git metadata for this deployment
    Value: !Sub '${GitSha} from ${GitBranch} (${GitRepo})'
```

**Usage:**
```bash
# Parameters are automatically injected by trupositive
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-app \
  --capabilities CAPABILITY_IAM

# Verify tags
aws cloudformation describe-stacks \
  --stack-name my-app \
  --query 'Stacks[0].Tags'
```

See full example: [examples/cloudformation/](cloudformation/)

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Important: fetch full history for Git metadata
      
      - name: Install trupositive
        run: |
          curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Deploy with Terraform
        run: |
          cd terraform/
          trupositive init
          terraform init
          terraform apply -auto-approve
        # Git metadata automatically injected via TF_VAR_* environment variables
```

### GitLab CI

```yaml
# .gitlab-ci.yml
deploy:
  image: hashicorp/terraform:latest
  stage: deploy
  before_script:
    - apk add bash curl git
    - curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
    - export PATH="$HOME/.local/bin:$PATH"
  script:
    - cd terraform/
    - trupositive init
    - terraform init
    - terraform apply -auto-approve
  only:
    - main
```

### Jenkins

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    stages {
        stage('Install trupositive') {
            steps {
                sh '''
                    curl -fsSL https://raw.githubusercontent.com/trupositive-ai/trupositive/main/install.sh | bash
                    export PATH="$HOME/.local/bin:$PATH"
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    export PATH="$HOME/.local/bin:$PATH"
                    cd terraform/
                    trupositive init
                    terraform init
                    terraform apply -auto-approve
                '''
            }
        }
    }
}
```

## Tips & Best Practices

### 1. Always Initialize First
```bash
trupositive init  # Generates config before first deployment
```

### 2. Verify Tags After Deployment
```bash
# AWS CLI
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=git_sha,Values=* \
  --query 'ResourceTagMappingList[0].Tags'

# Terraform
terraform show -json | jq '.values.root_module.resources[].values.tags'
```

### 3. Handle Tag Drift
If tags are manually changed, re-apply your infrastructure:
```bash
terraform apply -refresh-only  # Update state
terraform apply                # Restore tags
```

### 4. Multi-Environment Setup
Use different branches for different environments:
```bash
# Development
git checkout develop
terraform apply  # Tags with git_branch=develop

# Production
git checkout main
terraform apply  # Tags with git_branch=main
```

### 5. Debugging
Check what Git metadata trupositive detects:
```bash
git rev-parse HEAD           # Commit SHA
git rev-parse --abbrev-ref HEAD  # Branch name
git config --get remote.origin.url  # Repo URL
```

## Common Issues

### Issue: Tags not appearing
**Solution:** Ensure you're in a Git repository with at least one commit.

### Issue: "unknown" values in tags
**Solution:** 
- Check you're in a Git repo: `git status`
- Ensure you have commits: `git log`
- Verify remotes: `git remote -v`

### Issue: Azure/GCP tags not applied
**Solution:** These providers require manual tag application. Use `tags = local.default_tags` on each resource.

### Issue: CI/CD shows wrong branch
**Solution:** Ensure your CI fetches the full Git history:
```yaml
# GitHub Actions
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Fetch all history
```

## More Examples

For complete, runnable examples, see:
- [Terraform AWS Examples](terraform/aws/) - EC2, RDS, Lambda, S3
- [Terraform Azure Examples](terraform/azure/) - VMs, Storage, AKS
- [Terraform GCP Examples](terraform/gcp/) - GCE, GCS, GKE
- [CloudFormation Examples](cloudformation/) - Multi-tier application stacks

## Contributing Examples

Have a useful example? [Open a PR](https://github.com/trupositive-ai/trupositive/pulls) or [create an issue](https://github.com/trupositive-ai/trupositive/issues).
