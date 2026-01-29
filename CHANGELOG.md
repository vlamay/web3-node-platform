# Changelog

All notable changes to the Web3 Node Platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Terraform CI workflow for infrastructure validation
- Automated Release workflow with changelog generation
- Kustomize overlays for multi-environment deployments

## [0.2.0] - 2026-01-29

### Added
- **GitOps Foundation**: ArgoCD Application manifest and documentation
- **Disaster Recovery**: Velero backup configs with S3/IAM Terraform module
- **Centralized Logging**: Loki + Promtail stack configuration
- **Multi-Environment Support**: Terraform envs for dev/prod
- **Cost Optimization**: FinOps guide with tagging policies

### Changed
- Enhanced CI to exclude Helm values from kubeconform validation
- Updated security hardening (seccomp, capabilities drop)

### Security
- Fixed `GETH_PORT` environment variable conflict
- Removed init-permissions container in favor of fsGroup

## [0.1.0] - 2026-01-28

### Added
- Initial Kubernetes manifests for Geth Ethereum node
- StatefulSet with comprehensive resource configuration
- Prometheus + Grafana observability stack
- GitHub Actions CI/CD pipeline
- Terraform modules for AWS EKS deployment
- Comprehensive documentation (deployment, architecture, monitoring)
- Local development support via Kind
- Security hardening (NetworkPolicies, RBAC, non-root containers)

[Unreleased]: https://github.com/vlamay/web3-node-platform/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/vlamay/web3-node-platform/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/vlamay/web3-node-platform/releases/tag/v0.1.0
