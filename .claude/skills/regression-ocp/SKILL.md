---
name: regression-ocp
description: Execute comprehensive regression tests for Kiali on OpenShift clusters, including environment setup, test execution, log collection, and failure reporting
disable-model-invocation: true
user-invocable: true
---

# OpenShift Regression Testing Skill

This skill automates the complete regression testing workflow for Kiali on OpenShift clusters.

**EXECUTION**: Run the script at `scripts/regression-ocp.sh` with the provided arguments.

## How to Execute This Skill

When invoked as `/regression-ocp` or when requested to run OpenShift regression tests:

1. Change to the skill directory:
   ```bash
   cd .claude/skills/regression-ocp
   ```

2. Execute the script with user-provided arguments:
   ```bash
   ./scripts/regression-ocp.sh $ARGUMENTS
   ```

3. If no arguments provided, run with defaults:
   ```bash
   ./scripts/regression-ocp.sh
   ```

The script handles all workflow steps automatically and provides colored output for progress tracking.

## When to Use

Invoke this skill when you need to:
- Run comprehensive regression tests on OpenShift (remote or CRC)
- Validate that code changes haven't broken existing functionality
- Test Kiali + OSSMC + Istio integration on OpenShift
- Collect detailed logs and artifacts from test failures

## What This Skill Does

1. **Validates Prerequisites**
   - Checks for required tools (oc, yarn, node, stern)
   - Ensures you're logged into an OpenShift cluster
   - Verifies cluster access and permissions

2. **Sets Up Environment**
   - Runs `hack/install-kiali-ossmc-openshift.sh` to install:
     - Istio (via istioctl)
     - Kiali Operator (via OLM)
     - Kiali CR
     - OSSMConsole CR
   - Waits for all components to be ready

3. **Configures Test Environment**
   - Discovers Kiali route URL automatically
   - Sets up authentication (kubeadmin by default, prompts for password)
   - Configures Cypress environment variables

4. **Executes Tests**
   - Runs Cypress test suite with specified test group
   - Enables stern logging for real-time pod logs (optional)
   - Records videos of test execution (optional)

5. **Collects Artifacts on Failure**
   - Gathers logs from Kiali, OSSMC, and Istio pods
   - Copies Cypress screenshots and videos
   - Collects environment information (versions, configurations)
   - Organizes everything in a timestamped directory

6. **Reports Results**
   - Provides summary of test results
   - Lists location of collected artifacts
   - Suggests next steps for debugging failures

## Usage

### Basic Usage

```bash
# Run full regression suite
/regression-ocp
```

The skill will prompt for OpenShift password if not already set in environment.

### Options

```bash
# Dry run - validate setup only, don't run tests
/regression-ocp --dry-run

# Run specific test group
/regression-ocp --test-group "@smoke"

# Skip installation (if already installed)
/regression-ocp --skip-install

# Enable video recording (disabled by default)
/regression-ocp --with-video

# Disable stern logging
/regression-ocp --no-stern

# Show help
/regression-ocp --help
```

### Environment Variables

You can customize behavior with environment variables:

```bash
# Authentication
export CYPRESS_USERNAME="kubeadmin"        # Default: kubeadmin
export CYPRESS_PASSWD="your-password"      # Prompts if not set
export CYPRESS_AUTH_PROVIDER="kube:admin"  # Default: kube:admin

# Test configuration
export TEST_GROUP="@smoke"                 # Default: "not @multi-cluster"
export CYPRESS_VIDEO=true                  # Default: false
export CYPRESS_STERN=false                 # Default: true

# Then run
/regression-ocp
```

## Prerequisites

Before running this skill:

1. **OpenShift Access**
   - You must be logged into an OpenShift cluster: `oc login <cluster-url>`
   - OR the installation script will attempt to start CRC

2. **Required Tools**
   - `oc` - OpenShift CLI
   - `node` - Node.js runtime
   - `yarn` - Package manager
   - `stern` - (optional) Multi-pod log tailing

3. **Repository State**
   - You must be in the kiali repository root
   - Frontend dependencies should be installed (`yarn install` in `frontend/`)

## Output

The skill provides:

1. **Progress Updates**
   - Real-time status of each workflow step
   - Color-coded output (info, success, warning, error)

2. **Test Results**
   - Summary of passed/failed tests
   - Exit code indicating success (0) or failure (non-zero)

3. **Artifacts (on failure)**
   - `regression-logs-YYYYMMDD-HHMMSS/` directory containing:
     - `kiali-logs.txt` - Kiali server logs
     - `ossmc-logs.txt` - OSSMC console logs
     - `istiod-logs.txt` - Istio control plane logs
     - `environment-info.txt` - Version and configuration info
     - `screenshots/` - Cypress failure screenshots
     - `videos/` - Test execution recordings

## Script Implementation

The skill is implemented by the script: `scripts/regression-ocp.sh`

See [reference.md](reference.md) for detailed documentation of the manual workflow.

## Related Workflows

- [Manual Regression Testing Workflow](../../workflows/REGRESSION_TESTING_OCP.md)
- [QE Tester Agent](../../agents/qe-tester/agent.md)

## Examples

### Run smoke tests only

```bash
export TEST_GROUP="@smoke"
/regression-ocp
```

### Quick validation (no tests)

```bash
/regression-ocp --dry-run
```

### Run tests on existing installation

```bash
/regression-ocp --skip-install
```

### Run with video recording enabled

```bash
/regression-ocp --with-video
```

## Troubleshooting

### "Not logged into OpenShift"
```bash
oc login https://api.your-cluster.com:6443
```

### "Missing required dependencies"
Install the missing tools:
- `oc`: Download from Red Hat OpenShift website
- `node`/`yarn`: Use nvm or package manager
- `stern`: `brew install stern` or download binary

### "Installation failed"
Check operator logs:
```bash
oc logs -n openshift-operators -l app.kubernetes.io/name=kiali-operator --tail=100
```

### Tests fail to authenticate
Verify credentials:
```bash
oc login -u ${CYPRESS_USERNAME}
```

### Need to re-run failed tests
```bash
# Keep the installation, just re-run tests
/regression-ocp --skip-install
```

## Integration with Agents

This skill can be invoked by the QE Tester agent:

```bash
@qe-tester run OpenShift regression tests
```

The agent will handle the skill invocation and monitor progress.
