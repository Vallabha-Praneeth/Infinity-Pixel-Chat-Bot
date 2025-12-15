# Contributing to Infinity Pixel Chat Bot

First off, thank you for considering contributing to Infinity Pixel Chat Bot! It's people like you that make this project better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project and everyone participating in it is governed by our commitment to creating a welcoming and inclusive environment. By participating, you are expected to uphold this standard.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior** vs. actual behavior
- **Screenshots** if applicable
- **Environment details** (n8n version, OS, etc.)

Use the bug report template when creating an issue.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** explaining why this would be useful
- **Possible implementation** if you have ideas
- **Examples** from other projects if applicable

### Code Contributions

#### Good First Issues

Look for issues labeled `good first issue` - these are great starting points for new contributors.

#### Areas for Contribution

- **Documentation improvements**
- **Test coverage expansion**
- **Bug fixes**
- **New workflow features**
- **Performance optimizations**
- **UI/UX enhancements**

## Getting Started

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/Infinity-Pixel-Chat-Bot.git
   cd Infinity-Pixel-Chat-Bot
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/Vallabha-Praneeth/Infinity-Pixel-Chat-Bot.git
   ```

4. **Set up environment**
   ```bash
   export N8N_WEBHOOK_BASE="https://your-n8n-instance.app.n8n.cloud"
   export N8N_TICKET_WEBHOOK_PATH="/webhook/tt"
   ```

5. **Run tests**
   ```bash
   cd tests
   ./all_test.sh
   ```

## Development Workflow

1. **Create a branch**
   ```bash
   git checkout -b feature/amazing-feature
   # or
   git checkout -b fix/bug-description
   ```

2. **Make your changes**
   - Write clear, readable code
   - Add comments for complex logic
   - Update documentation as needed

3. **Test your changes**
   ```bash
   cd tests
   ./all_test.sh
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: Brief description of changes"
   ```

5. **Pull latest changes**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

7. **Open a Pull Request**

## Coding Standards

### n8n Workflows

- **Clear node names**: Use descriptive names like "Code - Prepare Create Response"
- **Comments**: Add notes explaining complex logic
- **Error handling**: Include error branches for external API calls
- **Testing**: Test each branch independently

### Bash Scripts

- **POSIX compliant**: Ensure scripts work across different shells
- **Error handling**: Use `set -euo pipefail`
- **Comments**: Explain non-obvious logic
- **Usage examples**: Include usage instructions at the top

### Python Scripts

- **PEP 8**: Follow Python style guide
- **Type hints**: Use type annotations where appropriate
- **Docstrings**: Document functions and classes
- **Error handling**: Use try-except blocks appropriately

### Documentation

- **Markdown format**: Use proper heading hierarchy
- **Code blocks**: Include syntax highlighting
- **Examples**: Provide clear examples
- **Links**: Keep internal links up to date

## Commit Message Guidelines

We follow the Conventional Commits specification:

```
<type>: <description>

[optional body]

[optional footer]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```
feat: Add support for ticket priority escalation

Add automatic escalation logic when SLA is breached.
Includes notification to support team.

Closes #123
```

```
fix: Correct ticket ID preservation in close action

The close response was losing the ticket ID during
Airtable update operation. Now uses explicit node
reference to preserve the ID.

Fixes #456
```

```
docs: Update installation guide with Docker setup

Added Docker Compose configuration and updated
README with container-based installation steps.
```

## Pull Request Process

1. **Ensure tests pass**
   - All existing tests must pass
   - Add new tests for new features

2. **Update documentation**
   - Update README.md if needed
   - Update relevant docs in `docs/`
   - Add changelog entry

3. **Fill out PR template**
   - Describe your changes
   - Link related issues
   - Include screenshots if applicable

4. **Request review**
   - Tag relevant maintainers
   - Address review feedback promptly

5. **CI checks must pass**
   - All automated checks must be green
   - Fix any issues before merge

### PR Title Format

Use the same format as commit messages:

```
feat: Add automated SLA monitoring
fix: Resolve empty response in status check
docs: Improve quick start guide
```

## Testing Guidelines

### Before Submitting

Run the complete test suite:

```bash
cd tests
./all_test.sh
```

Expected output: All 6 tests passing ✓

### Adding New Tests

When adding features, include tests:

1. Create test script in `tests/`
2. Follow naming convention: `test_feature_name.sh`
3. Include clear pass/fail indicators
4. Update `all_test.sh` to include new test

### Test Coverage

Ensure your changes are covered by tests:

- **Happy path**: Normal operation
- **Error cases**: Invalid inputs, missing data
- **Edge cases**: Boundary conditions
- **Regression**: Ensure old functionality still works

## Questions?

- Open an issue for general questions
- Tag with `question` label
- Join discussions in existing issues

## Recognition

Contributors will be recognized in:

- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing! 🎉
