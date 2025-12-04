# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of Open WebUI AKS deployment solution
- Complete Terraform infrastructure automation
- Kubernetes manifests for Open WebUI and Ollama
- Azure Key Vault integration for secret management
- External Secrets Operator configuration
- Cloudflare Tunnel support for secure external access
- Microsoft OAuth 2.0 authentication
- Comprehensive documentation and usage examples
- Automated deployment script (`deploy.sh`)
- Contributing guidelines
- Security best practices documentation

### Infrastructure Components
- Azure Resource Group provisioning
- AKS cluster configuration
- Azure Storage Account for persistent data
- User-Assigned Managed Identity setup
- Azure Key Vault for secrets management
- Cloudflare Zero Trust Tunnel
- Azure AD App Registration for SSO

### Kubernetes Resources
- Namespace configuration
- Persistent Volume Claims for Ollama and Open WebUI
- Secret Store and External Secret configurations
- ConfigMap for application settings
- Ollama deployment with health checks
- Open WebUI deployment with OAuth integration
- Internal services for pod communication
- Cloudflare tunnel deployment

### Documentation
- Detailed README with architecture diagram
- Quick start guide
- Configuration examples
- Troubleshooting section
- Security considerations
- Customization options

## [1.0.0] - 2025-12-04

### Added
- Initial public release
- Production-ready infrastructure code
- Comprehensive documentation

---

## Release Notes Template

When creating a new release, copy this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security updates
```

---

## Version History

- **1.0.0** (2025-12-04) - Initial public release

[Unreleased]: https://github.com/yourusername/open-webui-aks-deployment/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/open-webui-aks-deployment/releases/tag/v1.0.0
