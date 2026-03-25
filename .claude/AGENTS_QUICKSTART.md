# Kiali Agents Quick Start Guide

This guide shows how to effectively use the experimental agents in this repository.

## What Are Agents?

Agents are specialized AI assistants with focused knowledge domains. Each agent has specific expertise and can help with particular types of tasks in the Kiali project.

## Available Agents

| Agent | Specialization | Common Tasks |
|-------|---------------|--------------|
| **qe-tester** | Testing & QA | Run tests, debug failures, validate quality |
| **operator-dev** | Operator Development | Work with operator, CRDs, Ansible playbooks |
| **backend-dev** | Go Backend | Implement APIs, backend features, Go code |
| **frontend-dev** | React/TypeScript UI | Build UI components, Redux, PatternFly |
| **cluster-ops** | Cluster Operations | Setup clusters, deploy Kiali, install Istio |

## How to Use Agents

### In Claude Code Conversations

Simply reference the agent you want to use in natural language:

```
Use the qe-tester agent to run the backend unit tests
```

```
Ask the cluster-ops agent to help me set up a minikube cluster with Istio
```

```
Use the backend-dev agent to implement a new REST endpoint for service metrics
```

```
Have the frontend-dev agent help me refactor the graph component
```

```
Use the operator-dev agent to update the Kiali CRD schema
```

### When to Use Which Agent

**Testing & Quality:**
- Use **qe-tester** for running tests, debugging test failures, setting up test environments

**Deploying & Operating:**
- Use **cluster-ops** for cluster setup, Istio installation, Kiali deployment, demo apps

**Developing Backend:**
- Use **backend-dev** for Go code, REST APIs, business logic, Kubernetes/Istio integration

**Developing Frontend:**
- Use **frontend-dev** for React components, TypeScript, Redux state, UI/UX

**Developing Operator:**
- Use **operator-dev** for operator code, CRDs, Ansible playbooks, Molecule tests

## Example Workflows

### Setting Up a Development Environment

```
Use the cluster-ops agent to:
1. Start a minikube cluster
2. Install Istio
3. Deploy Kiali with the operator
4. Install the Bookinfo demo
```

### Implementing a New Feature

**Backend API:**
```
Use the backend-dev agent to implement a new API endpoint that returns
aggregated metrics for a namespace
```

**Frontend Component:**
```
Use the frontend-dev agent to create a new metrics dashboard component
using PatternFly charts
```

### Running Tests

**Unit Tests:**
```
Use the qe-tester agent to run backend unit tests and check for failures
```

**Integration Tests:**
```
Use the qe-tester agent to run Cypress tests against the local development server
```

**Molecule Tests:**
```
Use the operator-dev agent to run molecule tests for the token-test scenario
```

### Troubleshooting

**Deployment Issues:**
```
Use the cluster-ops agent to debug why Kiali pods are not starting
```

**Test Failures:**
```
Use the qe-tester agent to investigate why the graph integration test is failing
```

**Operator Issues:**
```
Use the operator-dev agent to check why the Kiali CR is not reconciling
```

## Agent Capabilities

Each agent has access to:

- **Comprehensive documentation** via AGENTS.md
- **Specialized knowledge** in their domain
- **Common commands** and workflows
- **Best practices** and coding standards
- **Troubleshooting guides** for their area
- **Persistent memory** (auto-managed)

## Tips for Working with Agents

1. **Be specific**: "Use the qe-tester agent to run backend tests" is better than "run tests"

2. **Chain tasks**: You can ask an agent to complete multi-step workflows
   ```
   Use the cluster-ops agent to set up a minikube cluster, install Istio,
   build and deploy Kiali, and install the Bookinfo demo
   ```

3. **Switch agents**: Use different agents for different parts of a task
   ```
   Use the backend-dev agent to implement the API
   Then use the qe-tester agent to write tests for it
   ```

4. **Ask for guidance**: Agents can explain processes and suggest approaches
   ```
   Ask the operator-dev agent what files need to be updated when adding
   a new CRD field
   ```

5. **Leverage memory**: Agents remember context from your conversation
   ```
   Use the qe-tester agent to run the tests we discussed earlier
   ```

## Further Reading

- **[AGENTS.md](../../AGENTS.md)** - Comprehensive development guide for Kiali
- **[agents/README.md](agents/README.md)** - Detailed agent documentation
- **[CLAUDE.md](CLAUDE.md)** - Claude Code configuration for this project
- **[CONTRIBUTING.md](../../CONTRIBUTING.md)** - General contribution guidelines

## Quick Reference

### Common Agent Commands

**QE Tester:**
```bash
make test                    # Backend tests
make cypress-gui            # Frontend tests (GUI)
./hack/run-molecule-tests.sh  # Molecule tests
```

**Cluster Ops:**
```bash
./hack/k8s-minikube.sh -mp minikube start
./hack/istio/install-istio-via-istioctl.sh
make CLUSTER_TYPE=minikube operator-create kiali-create
```

**Backend Dev:**
```bash
make build                  # Build backend
make run-backend           # Run with hot-reload
make format lint           # Code quality
```

**Frontend Dev:**
```bash
make build-ui              # Build frontend
make run-frontend          # Dev server with hot-reload
make cypress-gui           # Run tests
```

**Operator Dev:**
```bash
make cluster-push-operator # Build and push
make operator-create       # Deploy operator
make run-operator-playbook-kiali  # Test playbook
```

---

**Need help?** Ask any agent for guidance on their specific domain!
