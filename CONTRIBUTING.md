# Contributing

## Reporting Issues

- Check existing issues first
- Include: clear description, steps to reproduce, environment details

## Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following existing code style
4. Test your changes
5. Submit a PR with clear description

## Code Style

- Use `set -e` for error handling
- Quote all variables: `"$variable"`
- Use `local` for function variables
- Provide clear error messages
- Use `>&2` for error output

## Testing

Test manually on different shells (bash, zsh) and operating systems when possible.

