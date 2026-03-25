# Kiali Experimental Agents

This directory contains experimental agent definitions for Claude Code to help with various Kiali development tasks.

## Available Agents

### QE Tester (`qe-tester`)
Quality Engineering specialist focused on:
- Backend testing (Go unit tests, integration tests)
- Frontend testing (Cypress UI tests)
- Operator testing (Molecule tests)
- Test environment setup and debugging
- Quality validation workflows

**When to use**: Running tests, debugging test failures, setting up test environments, validating code quality.

### Operator Developer (`operator-dev`)
Kiali operator development specialist focused on:
- Ansible playbook development
- Operator deployment (Helm and OLM)
- CRD (Custom Resource Definition) management
- Molecule test development
- Operator configuration and troubleshooting

**When to use**: Working with the Kiali operator, modifying CRDs, running Molecule tests, operator deployment issues.

### Backend Developer (`backend-dev`)
Go backend development specialist focused on:
- REST API implementation
- Kubernetes/Istio API integration
- Backend business logic
- Performance optimization
- Security best practices

**When to use**: Implementing backend features, working with Go code, API design, backend debugging.

### Frontend Developer (`frontend-dev`)
TypeScript/React frontend specialist focused on:
- React component development
- PatternFly UI implementation
- Redux state management
- Cypress testing
- Internationalization (i18n)

**When to use**: Implementing UI features, working with React/TypeScript, frontend debugging, UI/UX improvements.

### Cluster Operations (`cluster-ops`)
Kubernetes cluster operations specialist focused on:
- Cluster setup (Minikube, KinD, OpenShift/CRC)
- Istio installation and configuration
- Kiali deployment to clusters
- Demo application deployment
- Cluster troubleshooting and debugging

**When to use**: Setting up development clusters, deploying Kiali, installing Istio, troubleshooting cluster issues, managing demo apps.

## Usage

Agents can be invoked using the Agent tool in Claude Code:

```
Use the qe-tester agent to run the backend tests
Use the operator-dev agent to help deploy the operator to minikube
Use the backend-dev agent to implement the new API endpoint
Use the frontend-dev agent to fix the navigation component
```

Each agent has specialized knowledge and capabilities for specific tasks within the Kiali project.

## Agent Structure

Each agent directory contains:
- `agent.md` - Agent definition, instructions, and specialized knowledge
- `memory/` - Persistent memory for the agent (auto-managed by Claude Code)

## Creating New Agents

To create a new agent:

1. **Create directory structure**:
   ```bash
   mkdir -p .claude/agents/<agent-name>
   ```

2. **Create agent definition**:
   Create `agent.md` with:
   - Agent role and specialization
   - Key responsibilities
   - Important context and references
   - Common commands
   - Best practices

3. **Document in this README**:
   Add the agent to the "Available Agents" section above.

## Agent Best Practices

- **Focused scope**: Each agent should specialize in a specific domain
- **Reference AGENTS.md**: Agents should reference the comprehensive guide
- **Include commands**: Provide ready-to-use command examples
- **Context-aware**: Include environment setup and prerequisites
- **Memory enabled**: Agents automatically get persistent memory

## References

- [AGENTS.md](../../../AGENTS.md) - Comprehensive AI agent development guide for Kiali
- [CLAUDE.md](../CLAUDE.md) - Project-wide Claude configuration
- [CONTRIBUTING.md](../../../CONTRIBUTING.md) - Contributing guidelines
- [STYLE_GUIDE.adoc](../../../STYLE_GUIDE.adoc) - Code style guide
