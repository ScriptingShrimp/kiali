# Kiali Claude Code Plugin

## Project Overview

Kiali is a management console for Istio service mesh. It provides observability into the service mesh topology, health, metrics, and configuration.

**Architecture:**
- **Backend**: Go-based REST API server (go 1.25.8)
- **Frontend**: Node.js/React/TypeScript UI (requires Node.js >= 20)
- **Service Mesh**: Integrates with Istio for Kubernetes/OpenShift
- **AI Integration**: Developer preview ChatBot feature using OpenAI API

**Repository Structure:**
This is the main `kiali/kiali` repo. The full project includes:
- `kiali/kiali` - Main server and UI (this repo)
- `kiali/kiali-operator` - Operator repo (should be symlinked as `operator/`)
- `kiali/helm-charts` - Helm charts repo

## Critical Build Requirements

**IMPORTANT - Build Order:**
1. **Always build UI first**: `make build-ui`
2. **Then build backend**: `make build`

**Frontend Tooling:**
- Yarn is managed via [corepack](https://nodejs.org/api/corepack.html)
- Run `corepack enable` once before using `yarn`
- Exact Yarn version pinned in `frontend/package.json` (`packageManager` field)

**Required Tools:**
- Go (version in go.mod: 1.25.8) - verify with `make go-check`
- Node.js >= 20 with Corepack enabled
- Docker or Podman (set `DORP=podman` if using Podman)
- git, gcc, GNU make
- kubectl or oc (set `CLIENT_EXE=kubectl` or `CLIENT_EXE=oc`)

## Essential Commands

```bash
# Complete build and test
make build-ui build test

# Local development with hot-reload (no cluster needed)
make build-ui                # Terminal 1 (once)
make run-backend             # Terminal 1 (hot-reloads)
make run-frontend            # Terminal 2 (hot-reloads, opens browser)

# Format and lint before committing
make format lint

# Clean builds
make clean        # Backend only
make clean-ui     # Frontend only
make clean-all    # Everything
```

## Code Quality Standards (Critical)

**Before Committing:**
1. Run `make format lint`
2. Run `make test`
3. Remove all trailing whitespace from modified lines
4. Sort struct fields alphabetically when adding/modifying Go structs
5. Sort YAML keys alphabetically when adding/modifying YAML

**Go Standards:**
- Use `any` instead of `interface{}`
- Three import groups: standard library, third-party, Kiali
- Comments explain "why", not "what"

**TypeScript Standards:**
- Files: PascalCase (e.g., `ServiceList.ts`), except general files (camelCase)
- Variables/Functions: camelCase
- Event handlers: `handle` + event name (e.g., `handleClick`)
- Props: `on` + event name (e.g., `onClick`)
- Always use `t()` from `utils/I18nUtils` for translatable strings (NOT from `i18next`)

**See AGENTS.md** for comprehensive coding standards and style guide.

## Development Workflows

**Local Development (Fastest, No Cluster):**
```bash
make build-ui && make run-backend  # Terminal 1
make run-frontend                  # Terminal 2
```

**Cluster Development (Minikube Example):**
```bash
export CLUSTER_TYPE=minikube
export MINIKUBE_PROFILE=minikube
export DORP=docker
export CLIENT_EXE=kubectl

# Start cluster and install Istio
./hack/k8s-minikube.sh -mp ${MINIKUBE_PROFILE} start
./hack/istio/install-istio-via-istioctl.sh --client-exe ${CLIENT_EXE}

# Build and deploy
make CLUSTER_TYPE=minikube MINIKUBE_PROFILE=${MINIKUBE_PROFILE} build-ui build test cluster-push
make CLUSTER_TYPE=minikube MINIKUBE_PROFILE=${MINIKUBE_PROFILE} operator-create
make CLUSTER_TYPE=minikube MINIKUBE_PROFILE=${MINIKUBE_PROFILE} kiali-create

# Quick iteration after code changes
make CLUSTER_TYPE=minikube MINIKUBE_PROFILE=${MINIKUBE_PROFILE} \
  build cluster-push-kiali kiali-reload-image
```

**See AGENTS.md** for complete workflows for Minikube, KinD, and OpenShift.

## Testing

**Backend:**
```bash
make test                                              # All tests
make -e GO_TEST_FLAGS="-race -v -run=\"TestName\"" test  # Specific test
```

**Frontend:**
```bash
make cypress-gui  # Interactive
make cypress-run  # Headless
```

**Integration:**
```bash
./hack/run-integration-tests.sh  # Full suite (sets up cluster, Istio, Bookinfo)
```

**Molecule (Operator):**
```bash
# See AGENTS.md for detailed molecule test procedures
./hack/run-molecule-tests.sh --cluster-type minikube -udi true -at "token-test"
```

## Key Directories

- `business/` - Core business logic
- `handlers/` - HTTP request handlers
- `models/` - Data models
- `kubernetes/` - Kubernetes client interactions
- `prometheus/` - Prometheus integration
- `graph/` - Service graph generation
- `cache/` - Caching layer (see CACHE.md)
- `config/` - Configuration management
- `ai/` - AI ChatBot integration (dev preview)
- `frontend/` - React/TypeScript UI
- `tests/` - Integration tests
- `hack/` - Development scripts
- `operator/` - Symlink to kiali-operator repo

## Protected Files - NEVER MODIFY

**Versioned Operator Roles:**
- `operator/roles/v1.*/`, `operator/roles/v2.*/` - Only modify `roles/default/`

**Old CSV Versions:**
- `operator/manifests/*/[old-version]/` - Only modify LATEST version

**CRD Copies:**
- ANY CRD file EXCEPT `operator/crd-docs/crd/*.yaml`
- Golden copies in `crd-docs/crd/` are source of truth
- Sync with `make sync-crds` in operator repo

**Generated Files:**
- Anything in `_output/` directories

## Making Changes - Checklists

When making changes to resources or configuration, you MUST update multiple locations to support all installation methods (Helm, OLM, Operator).

**See AGENTS.md sections for detailed checklists:**
- Altering Kiali Operator Resources
- Altering Kiali Server Resources
- Altering Kiali Server Permissions
- Altering Configuration Settings
- Altering Monitoring Dashboard Templates
- Working with CRDs

**Example: Adding a new config setting requires updating 8+ files.**

## Important Documentation

**For Detailed Procedures, Read:**
- `AGENTS.md` - **Comprehensive development guide** (1400+ lines)
- `STYLE_GUIDE.adoc` - Code style requirements
- `CONTRIBUTING.md` - Contribution guidelines
- `CACHE.md` - Cache architecture
- `operator/DEVELOPING.adoc` - Operator development
- `RELEASING.md` - Release procedures

**For Context:**
- `README.adoc` - Project overview
- `AI_POLICY.md` - AI usage policy
- `CODE_OF_CONDUCT.md` - Community standards

## Common Pitfalls

1. **Building backend before UI** - Always `make build-ui` first
2. **Not enabling corepack** - Run `corepack enable` for yarn
3. **Modifying protected files** - See "Protected Files" section
4. **Skipping format/lint** - Always run `make format lint` before commit
5. **Not setting cluster env vars** - Set CLUSTER_TYPE, MINIKUBE_PROFILE/KIND_NAME, DORP, CLIENT_EXE
6. **Updating only one location** - Resource changes need updates in 3+ repos (see checklists in AGENTS.md)

## Git Workflow

**Current Branch:** cc-qe-plugin  
**Main Branch:** master  
**Git User:** Pavel Marek

Review recent commits with `git log` to match commit message style.

## When You Need Help

```bash
make help                          # All Makefile targets
./hack/k8s-minikube.sh --help     # Minikube script options
./hack/start-kind.sh --help       # KinD script options
./hack/crc-openshift.sh --help    # OpenShift script options
```

## Quick References

**Environment Variables to Set:**
- `CLUSTER_TYPE` (minikube, kind, or openshift)
- `MINIKUBE_PROFILE` (for minikube)
- `KIND_NAME` (for KinD)
- `DORP` (docker or podman)
- `CLIENT_EXE` (kubectl or oc)

**Most Common Tasks:**
- Local dev: See "Development Workflows" above
- Build everything: `make build-ui build test`
- Format code: `make format lint`
- Run tests: `make test`
- Deploy to cluster: See cluster-specific examples in AGENTS.md

## Community

- Issues/Features: https://github.com/kiali/kiali/issues
- Discussions: https://github.com/kiali/kiali/discussions
- Community: https://kiali.io/community/
- Documentation: https://kiali.io/docs
