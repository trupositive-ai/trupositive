# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest| :x:                |

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Report via:
1. GitHub's private security advisory feature
2. Email to repository maintainers

Include: description, steps to reproduce, potential impact, suggested fix (if any).

**Response Timeline:** Initial response within 48 hours, status update within 7 days.

## Security Considerations

- Installation script downloads from GitHub over HTTPS - review before running
- Git repository URLs are sanitized but visible in Terraform state files
- Review generated `trupositive.auto.tf` files before committing

