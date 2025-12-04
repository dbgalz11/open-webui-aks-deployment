# Contributing to Open WebUI AKS Deployment

First off, thank you for considering contributing to this project! 🎉

The following is a set of guidelines for contributing to this repository. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)

## Code of Conduct

This project and everyone participating in it is governed by common sense and mutual respect. By participating, you are expected to uphold this code. Please report unacceptable behavior by opening an issue.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, screenshots, etc.)
- **Describe the behavior you observed** and what you expected
- **Include your environment details** (OS, Terraform version, Azure CLI version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **Include examples** of how the feature would be used

### Your First Code Contribution

Unsure where to begin? You can start by looking through `beginner` and `help-wanted` issues:

- `beginner` - issues that should only require a few lines of code
- `help-wanted` - issues that are a bit more involved

### Pull Requests

1. Fork the repository and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure your code follows the existing style
4. Update documentation as needed
5. Make sure your commits follow the commit message guidelines

## Development Setup

### Prerequisites

- Terraform >= 1.14.0
- Azure CLI >= 2.50.0
- kubectl >= 1.28.0
- An Azure subscription
- A Cloudflare account

### Local Development

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/open-webui-aks-deployment.git
   cd open-webui-aks-deployment
   ```

2. Create a new branch:
   ```bash
   git checkout -b feature/my-new-feature
   ```

3. Make your changes and test them thoroughly

4. Commit your changes:
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

## Pull Request Process

1. **Update the README.md** with details of changes if applicable
2. **Update documentation** in relevant files
3. **Test your changes** in a real Azure environment if possible
4. **Ensure no sensitive information** is included in your commits
5. **Follow the commit message format** (see below)
6. **Request review** from maintainers

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(terraform): add support for multiple regions

docs(readme): update installation instructions

fix(kubernetes): correct PVC storage class configuration
```

## Coding Standards

### Terraform

- Use meaningful resource names
- Include comments for complex logic
- Use variables for values that might change
- Follow HashiCorp's [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use `terraform fmt` to format code

Example:
```terraform
# Good
resource "azurerm_resource_group" "open_webui" {
  name     = "${var.prefix}-rg"
  location = var.location
  
  tags = merge(
    var.common_tags,
    {
      Purpose = "Open WebUI Deployment"
    }
  )
}

# Bad
resource "azurerm_resource_group" "rg" {
  name     = "my-rg"
  location = "eastus"
}
```

### Kubernetes YAML

- Use descriptive names
- Include labels for organization
- Add comments for non-obvious configurations
- Use resource limits and requests
- Follow Kubernetes best practices

Example:
```yaml
# Good
apiVersion: apps/v1
kind: Deployment
metadata:
  name: open-webui
  namespace: open-webui
  labels:
    app: open-webui
    component: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: open-webui
  template:
    metadata:
      labels:
        app: open-webui
    spec:
      containers:
      - name: open-webui
        image: ghcr.io/open-webui/open-webui:main
        resources:
          requests:
            memory: "1Gi"
            cpu: "100m"
          limits:
            memory: "2Gi"
            cpu: "500m"
```

### Documentation

- Keep README.md up to date
- Use clear, concise language
- Include code examples where helpful
- Update the Table of Contents if adding new sections
- Verify all links work

## Testing

Before submitting a pull request:

1. **Terraform Validation:**
   ```bash
   cd tf_files
   terraform init
   terraform validate
   terraform fmt -check
   ```

2. **Kubernetes Validation:**
   ```bash
   cd yaml_files
   kubectl apply --dry-run=client -f .
   ```

3. **Test in a Dev Environment:**
   - Deploy to a test Azure subscription
   - Verify all resources are created correctly
   - Test the application functionality
   - Clean up resources after testing

## Security

- **Never commit secrets** or sensitive information
- Use Azure Key Vault for all secrets
- Follow the principle of least privilege
- Review the security implications of your changes

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🚀
