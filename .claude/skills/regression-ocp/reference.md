# Regression Testing Skill - OpenShift

**Skill Name:** `regression-ocp`

**Purpose:** Automate the execution of Kiali regression tests on a remote OpenShift cluster, including environment setup, test execution, log collection, and regression reporting.

## Invocation

```
/regression-ocp
```

Or via Claude Code:
```
Run OpenShift regression tests
```

## What This Skill Does

This skill automates the complete regression testing workflow for Kiali on OpenShift:

1. **Validates cluster access** - Ensures you're logged into an OpenShift cluster
2. **Installs or verifies components** - Runs the installation script for Istio, Kiali, and OSSMC
3. **Configures test environment** - Sets up all required environment variables for Cypress
4. **Executes regression tests** - Runs the Cypress test suite with OpenShift-specific settings
5. **Collects logs on failure** - Gathers logs from Kiali, OSSMC, Istio, and test output
6. **Reports results** - Creates a GitHub issue if regressions are detected (optional, confirms with user)

## Prerequisites

Before running this skill, ensure:

- [ ] You have access to a remote OpenShift cluster
- [ ] You're authenticated via `oc login` or the script will attempt to use CRC
- [ ] You have cluster-admin privileges
- [ ] Node.js and Yarn are installed
- [ ] You're in the kiali repository root directory

## Workflow Steps

### 1. Cluster Validation

The skill checks if you're logged into OpenShift:

```bash
oc whoami
```

If not logged in, it will inform you and you can either:
- Log in manually: `oc login <cluster-url>`
- Let the installation script start CRC (if available)

### 2. Component Installation

Executes the installation script:

```bash
./hack/install-kiali-ossmc-openshift.sh
```

This installs:
- Istio (in `istio-system` namespace)
- Kiali Operator (via OLM)
- Kiali CR (in `istio-system`)
- OSSMConsole CR (in `ossmconsole` namespace)

**Waits for all components to be ready.**

### 3. Environment Configuration

Automatically gathers and sets required environment variables:

```bash
# Get Kiali URL from OpenShift route
CYPRESS_BASE_URL=$(oc get route -n istio-system -l app.kubernetes.io/name=kiali -o jsonpath='https://{..spec.host}/')

# Get cluster URL for OSSMC
CLUSTER_URL=$(oc get console cluster -o jsonpath='{.status.consoleURL}')

# Authentication will use default OpenShift credentials or prompt user
CYPRESS_USERNAME="kubeadmin"
CYPRESS_AUTH_PROVIDER="kube:admin"
```

**User interaction:** The skill will ask you for the OpenShift password if needed.

### 4. Test Execution

Runs Cypress tests with OpenShift configuration:

```bash
cd frontend
export CYPRESS_BASE_URL=<kiali-url>
export CYPRESS_USERNAME=kubeadmin
export CYPRESS_PASSWD=<password>
export CYPRESS_AUTH_PROVIDER="kube:admin"
export TEST_GROUP="not @multi-cluster"  # Default for single-cluster
export CYPRESS_STERN=true  # Enable stern logging

yarn cypress:run
```

**Monitors test execution and captures results.**

### 5. Log Collection (On Failure)

If any tests fail, automatically collects:

**Kiali logs:**
```bash
oc logs -n istio-system -l app.kubernetes.io/name=kiali --tail=1000 > kiali-logs.txt
```

**OSSMC logs:**
```bash
oc logs -n ossmconsole -l app.kubernetes.io/name=ossmconsole --tail=1000 > ossmc-logs.txt
```

**Istio logs:**
```bash
oc logs -n istio-system -l app=istiod --tail=1000 > istiod-logs.txt
```

**Test artifacts:**
- Screenshots from `frontend/cypress/screenshots/`
- Videos from `frontend/cypress/videos/`
- Cypress console output

### 6. Regression Reporting

If regressions are detected, the skill:

1. **Summarizes results:**
   - Total tests run
   - Pass/fail counts
   - Failed test names and errors

2. **Gathers environment info:**
   - OpenShift version
   - Istio version
   - Kiali version
   - OSSMC version

3. **Asks user for confirmation** to create a GitHub issue

4. **Creates formatted issue** with:
   - Test summary
   - Environment details
   - Failed test information
   - Log file attachments
   - Screenshots of failures

## Configuration Options

The skill can be customized by setting environment variables before invocation:

```bash
# Run specific test groups
export TEST_GROUP="@smoke"

# Disable stern logging
export CYPRESS_STERN=false

# Use custom username
export CYPRESS_USERNAME="admin"
export CYPRESS_AUTH_PROVIDER="my-auth-provider"

# Run headless without video (faster)
export CYPRESS_VIDEO=false
```

## Output

The skill provides:

1. **Real-time progress updates** during each step
2. **Installation logs** from the setup script
3. **Test execution output** from Cypress
4. **Summary report** at completion:
   ```
   ========================================
   Regression Test Summary
   ========================================
   Total Tests:    150
   Passed:         148
   Failed:         2
   Duration:       12m 34s
   Test Group:     not @multi-cluster

   Environment:
   - OpenShift:    4.14.0
   - Istio:        1.20.1
   - Kiali:        1.80.0
   - OSSMC:        1.80.0

   Failed Tests:
   1. Graph display > should render service graph
   2. Workload logs > should show container logs

   Logs collected in:
   - kiali-logs.txt
   - ossmc-logs.txt
   - istiod-logs.txt
   - frontend/cypress/screenshots/
   - frontend/cypress/videos/

   Create GitHub issue? (y/n)
   ========================================
   ```

## Error Handling

The skill handles common errors:

- **Not logged into cluster:** Prompts to log in or use CRC
- **Installation failures:** Reports error and stops, suggests checking operator logs
- **Test execution failures:** Continues to log collection and reporting
- **Missing dependencies:** Reports which tools are missing (oc, yarn, stern)

## Example Usage

### Basic regression run:

```
/regression-ocp
```

The skill will:
1. Validate your cluster access
2. Install/verify components
3. Run all non-multi-cluster tests
4. Report any failures

### With custom test group:

```bash
export TEST_GROUP="@smoke"
/regression-ocp
```

Runs only smoke tests.

### Dry run (validate setup only):

```bash
export DRY_RUN=true
/regression-ocp
```

Validates cluster access and component installation without running tests.

## Integration with QE Tester Agent

This skill is designed to work with the `qe-tester` agent:

```
@qe-tester run regression tests on OpenShift cluster
```

The agent will:
- Invoke this skill
- Monitor progress
- Handle any interactive prompts
- Create detailed regression reports

## Files Created

After execution, you'll find:

```
/home/scsh/work/github.com/scriptingshrimp/kiali/
├── kiali-logs.txt              # Kiali pod logs
├── ossmc-logs.txt              # OSSMC pod logs
├── istiod-logs.txt             # Istio control plane logs
└── frontend/
    └── cypress/
        ├── screenshots/        # Test failure screenshots
        ├── videos/            # Test execution videos
        └── results/           # JUnit XML reports (if configured)
```

## Cleanup

To clean up the OpenShift environment after testing:

```bash
# Delete OSSMC
oc delete ossmconsole ossmconsole -n ossmconsole

# Delete Kiali
oc delete kiali kiali -n istio-system

# Uninstall operator
oc delete subscription kiali -n openshift-operators
```

Or use the make target:
```bash
make operator-delete
```

## Related Documentation

- [Regression Testing Workflow](../workflows/REGRESSION_TESTING_OCP.md) - Detailed manual workflow
- [Cypress README](../../frontend/cypress/README.md) - Cypress testing guide
- [OSSMC Documentation](../../WORKING_WITH_OSSMC.md) - OSSMC installation and usage
- [QE Tester Agent](../agents/qe-tester/agent.md) - Agent that can invoke this skill

## Maintenance Notes

This skill should be updated when:
- Installation script location or name changes
- New test groups are added to Cypress
- Environment variable requirements change
- Reporting format needs adjustment
