# OpenShift Regression Testing Workflow

This document describes the manual Quality Engineering workflow for running regression tests against Kiali deployed on a remote OpenShift cluster.

## Overview

This workflow is used to validate that code changes haven't broken existing functionality. It's a comprehensive process that involves:
1. Setting up a remote OpenShift environment
2. Installing Istio, Kiali, and OSSMC
3. Executing the Cypress test suite with OpenShift-specific configuration
4. Collecting logs and test results
5. Reporting any regressions found

## When to Use

- **Before major releases** - Validate the entire system before shipping
- **After significant changes** - Verify refactoring or architectural changes
- **Manual execution** - This workflow is currently manual due to its complexity and resource requirements

## Prerequisites

- Access to a remote OpenShift cluster (with cluster-admin privileges)
- `oc` CLI tool installed and configured
- Node.js and Yarn installed (for running Cypress tests)
- GitHub access for creating regression reports (if issues are found)

## Workflow Steps

### Step 1: Set Up OpenShift Environment

Ensure you have access to a remote OpenShift cluster. You should be able to authenticate and run:

```bash
oc whoami
```

If not already logged in:

```bash
oc login <cluster-api-url> -u <username> -p <password>
```

**Expected outcome:** You're authenticated to the OpenShift cluster and have cluster-admin privileges.

---

### Step 2: Install Istio, Kiali, and OSSMC

Use the installation script located in the kiali repository:

```bash
./hack/install-kiali-ossmc-openshift.sh
```

**What this script does:**
- Checks if you're logged into OpenShift (or starts CRC if not)
- Installs Istio via istioctl (if not already present)
  - Uses: `./hack/istio/install-istio-via-istioctl.sh -c oc`
  - Instio namespace: `istio-system`
- Installs Kiali Operator via OLM Subscription
  - Creates subscription in `openshift-operators` namespace
  - Uses `community-operators` catalog
- Creates Kiali CR in `istio-system` namespace
- Creates OSSMConsole CR in `ossmconsole` namespace
- Waits for all components to be ready

**Expected outcome:**
- Istio is running in `istio-system`
- Kiali is running in `istio-system`
- OSSMC is running in `ossmconsole`
- Console URLs are displayed

**Verification:**

```bash
# Check Istio
oc get pods -n istio-system -l app=istiod

# Check Kiali
oc get pods -n istio-system -l app.kubernetes.io/name=kiali

# Check OSSMC
oc get pods -n ossmconsole -l app.kubernetes.io/name=ossmconsole

# Get URLs
CLUSTER_URL=$(oc get console cluster -o jsonpath='{.status.consoleURL}')
echo "OSSMC URL: ${CLUSTER_URL}/ossmconsole/overview"

KIALI_URL=$(oc get route -n istio-system -l app.kubernetes.io/name=kiali -o jsonpath='https://{..spec.host}/')
echo "Kiali URL: ${KIALI_URL}"
```

---

### Step 3: Execute Cypress Tests with OpenShift Configuration

Navigate to the frontend directory and run Cypress tests with OCP-specific environment variables.

**Required Environment Variables:**

```bash
# Get the Kiali URL from the route
export CYPRESS_BASE_URL=$(oc get route -n istio-system -l app.kubernetes.io/name=kiali -o jsonpath='https://{..spec.host}/')

# Set authentication credentials
export CYPRESS_USERNAME="kubeadmin"  # or your OpenShift username
export CYPRESS_PASSWD="<your-password>"

# Set the authentication provider
export CYPRESS_AUTH_PROVIDER="kube:admin"  # or your auth provider

# Optional: Define test groups to run
export TEST_GROUP="not @multi-cluster"  # Exclude multi-cluster tests for single-cluster setup

# Optional: Enable stern logging for enhanced log collection
export CYPRESS_STERN=true
```

**Run the tests:**

From the repository root:

```bash
cd frontend
yarn cypress:run
```

Or from the root using make targets (if available):

```bash
make cypress-run
```

**What happens during execution:**
- Cypress connects to the Kiali instance at CYPRESS_BASE_URL
- Tests authenticate using the provided credentials
- BDD feature files are executed (from `cypress/integration/featureFiles/`)
- If CYPRESS_STERN=true, stern is used to tail logs from running pods
- Test results, screenshots (on failure), and videos are saved in `frontend/cypress/`

**Expected outcome:**
- Tests execute and report pass/fail status
- Screenshots captured for failed tests (in `frontend/cypress/screenshots/`)
- Videos recorded (in `frontend/cypress/videos/`)
- JUnit XML reports generated (if configured)

---

### Step 4: Collect Logs

Gather logs from the cluster to aid in debugging any failures:

**Kiali Pod Logs:**

```bash
oc logs -n istio-system -l app.kubernetes.io/name=kiali --tail=500 > kiali-logs.txt
```

**OSSMC Pod Logs:**

```bash
oc logs -n ossmconsole -l app.kubernetes.io/name=ossmconsole --tail=500 > ossmc-logs.txt
```

**Istio Control Plane Logs:**

```bash
oc logs -n istio-system -l app=istiod --tail=500 > istiod-logs.txt
```

**Cypress Test Output:**
- Already collected in `frontend/cypress/screenshots/` and `frontend/cypress/videos/`
- Console output from the test run

**Optional: Use stern for live logging (if CYPRESS_STERN=true):**

Stern automatically tails logs from pods matching certain labels during test execution. Make sure stern is installed.

---

### Step 5: Report Regressions

If any tests fail (regressions detected), create a GitHub issue with the collected information.

**Information to Include:**

1. **Test Summary**
   - Total tests run
   - Number of passes
   - Number of failures
   - Test duration
   - Test groups executed (from TEST_GROUP)

2. **Environment Information**
   - Cluster type: Remote OpenShift
   - OpenShift version: `oc version`
   - Istio version: `oc get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].spec.containers[0].image}'`
   - Kiali version: `oc get kiali -n istio-system kiali -o jsonpath='{.spec.version}'` or from the Kiali pod image
   - OSSMC version: Similar to Kiali

3. **Failed Test Details**
   - Test name/scenario
   - Error message
   - Stack trace (if available)
   - Screenshot (attach from `frontend/cypress/screenshots/`)
   - Video (if helpful, from `frontend/cypress/videos/`)

4. **Log Attachments**
   - Kiali logs (`kiali-logs.txt`)
   - OSSMC logs (`ossmc-logs.txt`)
   - Istio logs (`istiod-logs.txt`)
   - Relevant Cypress console output

**GitHub Issue Format:**

```markdown
## Regression Test Failure - [Date]

### Summary
- **Total Tests:** XX
- **Passed:** XX
- **Failed:** XX
- **Duration:** XX minutes
- **Test Group:** [e.g., "not @multi-cluster"]

### Environment
- **Cluster:** Remote OpenShift
- **OpenShift Version:** X.XX
- **Istio Version:** X.XX.X
- **Kiali Version:** X.XX.X
- **OSSMC Version:** X.XX.X

### Failed Tests

#### Test: [Test Name]
**Error:**
```
[Error message]
```

**Screenshot:** [attach]
**Video:** [attach or link]

### Logs
- [Attach kiali-logs.txt]
- [Attach ossmc-logs.txt]
- [Attach istiod-logs.txt]

### Steps to Reproduce
1. ...
2. ...
```

---

## Tips and Troubleshooting

### Tests are slow or flaky
- Set `CYPRESS_NUM_TESTS_KEPT_IN_MEMORY=0` to reduce memory usage
- Enable video recording: `CYPRESS_VIDEO=true`
- Wait for loading spinners to disappear before assertions

### Authentication issues
- Verify `CYPRESS_AUTH_PROVIDER` matches your cluster's auth method
- Check credentials are correct
- Ensure the Kiali route is accessible from your machine

### Installation failures
- Check if CRDs are established: `oc get crds | grep kiali`
- Verify operator is running: `oc get pods -n openshift-operators | grep kiali`
- Check operator logs: `oc logs -n openshift-operators -l app.kubernetes.io/name=kiali-operator`

### Log collection
- Use `--tail=500` to limit log size, or remove for full logs
- Use `--previous` flag if pod has restarted: `oc logs --previous ...`
- Use stern for real-time multi-pod logging: `stern -n istio-system kiali`

---

## Automation Opportunities

This workflow can be automated using the `/regression-ocp` skill (see separate skill documentation).

Automation candidates:
1. Environment setup validation
2. Installation script execution with error handling
3. Test execution with proper env var configuration
4. Automated log collection on test failure
5. GitHub issue creation with formatted report and attachments

---

## Related Documentation

- [Cypress Testing Guide](../../frontend/cypress/README.md)
- [OSSMC Documentation](../../WORKING_WITH_OSSMC.md)
- [Install Script](../../hack/install-kiali-ossmc-openshift.sh)
- [AGENTS.md](../../AGENTS.md) - General QE testing guidelines
