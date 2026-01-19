# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-XX-XX

### Added
- CloudFormation wrapper that automatically injects Git metadata as parameters
- Support for AWS CloudFormation alongside Terraform
- Automatic detection of infrastructure tool (Terraform vs CloudFormation)
- CloudFormation parameter template generation via `trupositive init`
- AWS CLI wrapper integration for seamless CloudFormation support
- Updated installation script to support both Terraform and CloudFormation
- Updated uninstallation script to remove CloudFormation wrappers

### Changed
- `trupositive init` now detects project type and generates appropriate configuration
- README updated with CloudFormation usage examples and documentation

## [1.0.0] - 2024-12-XX

### Added
- Terraform wrapper that injects Git metadata as variables
- `trupositive init` command for automatic Terraform tagging setup
- Support for AWS, Azure, and GCP providers
- CI/CD environment variable detection
- Installation and uninstallation scripts
- Input validation and security hardening

