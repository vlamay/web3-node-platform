# Contributing to Web3 Node Platform

Thank you for your interest in contributing! We welcome contributions to improve the infrastructure, documentation, and automation of this platform.

## Code of Conduct

Please treat everyone with respect and follow standard open-source etiquette.

## How to Contribute

1. **Fork the Repository**
2. **Create a Feature Branch** (`git checkout -b feature/amazing-feature`)
3. **Commit Your Changes** (`git commit -m 'feat: Add amazing feature'`)
4. **Push to the Branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

## Development Workflow

### Prerequisites
- Docker / Kind for local testing
- Terraform v1.6+
- pre-commit hooks (optional but recommended)

### Testing Changes
1. **Infrastructure:** Run `terraform validate` and `terraform plan` in `terraform/eks`.
2. **Kubernetes:** Run `./scripts/validate-config.sh` to check manifests.
3. **Local Deployment:** Use `make quick-test` to spin up a local Kind cluster and deploy the stack.

## Pull Request Guidelines

- **Title:** Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format (e.g., `feat:`, `fix:`, `docs:`).
- **Description:** Clearly explain what the PR does and why.
- **Tests:** Ensure all CI checks pass. Add new tests if adding features.
- **Documentation:** Update README.md or docs/ if changing architecture or commands.

## Issue Reporting

If you find a bug or have a feature request, please open an issue with:
- Clear title
- Description of the issue
- Steps to reproduce
- Expected behavior

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
