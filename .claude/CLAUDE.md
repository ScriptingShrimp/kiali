# Claude Configuration for Kiali

This directory contains Claude Code configuration and context for the Kiali project.

## Project Overview

Kiali is a management console for Istio service mesh. The project includes:
- **Backend**: Go-based server providing REST APIs and Kubernetes/Istio integration
- **Frontend**: TypeScript/React UI using PatternFly components
- **Operator**: Ansible-based operator for deploying and managing Kiali

## Essential Documentation

**IMPORTANT**: Always consult [AGENTS.md](../../AGENTS.md) for comprehensive development guidelines, including:
- Code quality standards (Go and TypeScript)
- Build and test procedures
- Cluster-specific workflows (Minikube, KinD, OpenShift)
- Operator development
- File protection rules and checklists

## Configuration Files

- `CLAUDE.md` - This file, containing project-specific instructions for Claude
- `agents/` - Experimental agent definitions for specialized tasks
- `memory/` - Auto-memory directory for persistent context across conversations

## Experimental Agents

This repository has experimental agents configured for specialized development tasks:

- **qe-tester** - Quality engineering, testing workflows, test execution
- **operator-dev** - Kiali operator development, deployment, and configuration
- **backend-dev** - Go backend development, API implementation
- **frontend-dev** - TypeScript/React frontend development, UI implementation
- **cluster-ops** - Cluster setup, Istio installation, Kiali deployment

See [agents/README.md](agents/README.md) for details.

## Agent Teams

**Agent teams are enabled** for this project. You can coordinate multiple Claude Code instances working together:

```
Create an agent team with a backend dev, frontend dev, and QE tester to
implement the new metrics dashboard feature
```

Agent teams allow parallel work with:
- Shared task list for coordination
- Direct communication between teammates
- Independent context windows per teammate

See the [Agent Teams documentation](https://code.claude.com/docs/en/agent-teams) for full details.

## Development Guidelines

### Code Quality Standards

**Go Backend:**
- Use `any` instead of `interface{}`
- No trailing whitespace
- Sort struct fields alphabetically
- Sort YAML keys alphabetically
- Organize imports: stdlib, third-party, kiali packages

**TypeScript Frontend:**
- Files: PascalCase (components) or camelCase (utilities)
- Variables/functions: camelCase
- Constants: UPPER_SNAKE_CASE (global) or camelCase (local)
- Event handlers: `handle` + event name
- Always use `t()` from `utils/I18nUtils` for i18n

### Common Commands

```bash
# Build everything
make build-ui build test

# Local development with hot-reload
make run-backend    # Terminal 1
make run-frontend   # Terminal 2

# Format and lint
make format lint

# Run tests
make test           # Backend tests
make cypress-gui    # Frontend tests (interactive)
make cypress-run    # Frontend tests (headless)
```

### Before Committing

- Run `make format lint`
- Run `make test`
- Remove trailing whitespace
- Sort struct fields and YAML keys alphabetically
- Ensure code follows standards in AGENTS.md

### Repository Structure

The Kiali project consists of multiple repositories:
- `kiali/` - Main server and UI repo (this repo)
- `kiali/operator/` - Symlink to kiali-operator repo
- `helm-charts/` - Helm charts repo (sibling directory)

## Important Reminders

- Always build UI before backend: `make build-ui` then `make build`
- Consult AGENTS.md checklists when modifying resources, CRDs, or configurations
- Never modify versioned operator roles, old CSV versions, or CRD copies
- Never modify `_output/` directories
