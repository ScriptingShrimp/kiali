---
name: cypress-test
description: Run specific Cypress tests with full stacktrace and error capture
disable-model-invocation: true
user-invocable: true
---

# Cypress Test Runner Skill

This skill runs specific Cypress tests with comprehensive error capture, including full stacktraces, screenshots, videos, and detailed logs.

**EXECUTION**: Run the script at `scripts/cypress-test.sh` with the provided test specification.

## How to Execute This Skill

When invoked as `/cypress-test` or when requested to run specific Cypress tests:

1. **Execute the script from the skill directory**:
   ```bash
   cd .claude/skills/cypress-test
   ./scripts/cypress-test.sh <test-spec> [options]
   ```

2. **Or execute from the repository root**:
   ```bash
   ./.claude/skills/cypress-test/scripts/cypress-test.sh <test-spec> [options]
   ```

The script will:
- Run the specified Cypress test(s)
- Capture full stacktraces from failures
- Save screenshots and videos
- Collect detailed error logs
- Generate a comprehensive test report

## When to Use

Invoke this skill when you need to:
- Run a specific Cypress test file or feature
- Debug failing tests with full stacktraces
- Capture detailed error information for bug reports
- Run tests with video recording enabled
- Execute tests with custom Cypress tags
- Get comprehensive test output for analysis

## What This Skill Does

1. **Validates Prerequisites**
   - Checks for required tools (node, yarn/npm, curl)
   - Verifies frontend directory exists
   - Ensures Cypress is installed

2. **Checks Kiali Instance** (Interactive)
   - Tests connectivity to Kiali API
   - If Kiali is not reachable, offers 4 options:
     1. Set up KinD cluster with integration tests (automated)
     2. Use local Kiali instance (prompts to start backend)
     3. Use custom Kiali URL (manual entry)
     4. Skip check and continue (may fail)
   - Automatically configures `CYPRESS_BASE_URL` based on selection

3. **Configures Test Environment**
   - Sets up Cypress configuration
   - Configures video and screenshot capture
   - Sets up error reporting
   - Applies any custom environment variables

4. **Executes Tests**
   - Runs the specified test file(s) or tags
   - Captures all console output
   - Records test execution (optional video)
   - Captures screenshots on failure

5. **Captures Full Stacktraces**
   - Collects complete error stacktraces from Cypress
   - Captures browser console errors
   - Records network failures
   - Saves DOM state on errors

6. **Generates Test Report**
   - Creates a detailed test report with:
     - Test results (passed/failed/skipped)
     - Full stacktraces for all failures
     - Screenshots and video links
     - Execution time and environment info
   - Saves artifacts in organized directory

7. **Reports Results**
   - Displays summary of test results
   - Shows location of captured artifacts
   - Provides error analysis and debugging hints

## Usage

### Basic Usage

```bash
# Run a specific feature file
/cypress-test graph/graph-side-panel.feature

# Run only tests annotated with @selected tag
/cypress-test graph/graph-side-panel.feature --selected

# Run tests with a specific tag
/cypress-test @smoke

# Run a specific scenario
/cypress-test "Login functionality"
```

### Options

```bash
# Run only tests annotated with @selected tag
/cypress-test <test-spec> --selected

# Enable video recording (disabled by default for speed)
/cypress-test <test-spec> --video

# Run in headless mode (default)
/cypress-test <test-spec> --headless

# Run in headed mode (opens browser)
/cypress-test <test-spec> --headed

# Specify browser
/cypress-test <test-spec> --browser chrome
/cypress-test <test-spec> --browser firefox
/cypress-test <test-spec> --browser edge

# Set base URL
/cypress-test <test-spec> --base-url http://localhost:3001

# Run with custom environment variables
/cypress-test <test-spec> --env USERNAME=admin,PASSWD=secret

# Set test group tag
/cypress-test <test-spec> --tag @smoke

# Specify output directory
/cypress-test <test-spec> --output-dir /path/to/output

# Enable debug mode (verbose logging)
/cypress-test <test-spec> --debug

# Show help
/cypress-test --help
```

### Combined Examples

```bash
# Run only selected tests in a feature file
/cypress-test graph/graph-side-panel.feature --selected

# Run smoke tests with video in Chrome
/cypress-test @smoke --video --browser chrome

# Debug a failing test with full output
/cypress-test login.feature --headed --debug

# Run tests against a specific environment
/cypress-test @core-1 --base-url https://kiali.example.com --env USERNAME=testuser,PASSWD=testpass
```

## Environment Variables

The following environment variables can be set before running the script:

```bash
# Cypress configuration
export CYPRESS_BASE_URL=<url>                    # Default: http://localhost:3001
export CYPRESS_USERNAME=<username>               # Default: from test config
export CYPRESS_PASSWD=<password>                 # Default: from test config
export CYPRESS_AUTH_PROVIDER=<provider>          # Default: from test config
export CYPRESS_ALLOW_INSECURE_KIALI_API=<bool>   # Default: false

# Test execution
export CYPRESS_VIDEO=<true|false>                # Default: false
export CYPRESS_BROWSER=<browser>                 # Default: electron
export CYPRESS_HEADED=<true|false>               # Default: false (headless)

# Output configuration
export CYPRESS_SCREENSHOTS_FOLDER=<path>         # Default: cypress/screenshots
export CYPRESS_VIDEOS_FOLDER=<path>              # Default: cypress/videos
export TEST_OUTPUT_DIR=<path>                    # Default: test-results-TIMESTAMP
```

## Prerequisites

1. **Node.js and Yarn**
   - `node` (>= 24.0.0)
   - `yarn` package manager

2. **Kiali Frontend**
   - Frontend dependencies installed (`yarn install` in `frontend/`)
   - Cypress installed

3. **Running Kiali Instance** (for integration tests)
   - **Option A: KinD Cluster Setup** (recommended for full integration tests)
     - Use `hack/run-integration-tests.sh` to set up the test environment
     - Kiali is exposed via LoadBalancer service in KinD
     - Get the URL with: `kubectl get svc kiali -n istio-system -o=jsonpath='http://{.status.loadBalancer.ingress[0].ip}/kiali'`
     - Set `CYPRESS_BASE_URL` to this URL
   - **Option B: Local Development**
     - Kiali backend running locally (default: http://localhost:3001)
     - Valid authentication credentials
   - **Option C: Mock Mode**
     - Use mock mode for UI-only tests (no backend required)

## Output

The skill provides:

1. **Console Output**
   - Real-time test execution progress
   - Test results summary
   - Error messages with stacktraces
   - Artifact locations

2. **Test Artifacts**
   - `test-results-YYYYMMDD-HHMMSS/` directory containing:
     - `test-report.txt` - Detailed test results
     - `stacktraces.txt` - Full stacktraces for all failures
     - `screenshots/` - Screenshots of failures
     - `videos/` - Test execution videos (if enabled)
     - `console-logs.txt` - Browser console output
     - `cypress-log.txt` - Full Cypress execution log

3. **Exit Code**
   - `0` - All tests passed
   - `1` - One or more tests failed
   - `2` - Error running tests (configuration, setup)

## Test Specification Format

The test specification can be:

1. **Feature file path** (relative to cypress/integration):
   ```bash
   /cypress-test graph/graph-side-panel.feature
   /cypress-test common/kiali-login.feature
   ```

2. **Cucumber tag**:
   ```bash
   /cypress-test @smoke
   /cypress-test "@core-1 or @core-2"
   /cypress-test "not @multi-cluster"
   ```

3. **Test name/description** (partial match):
   ```bash
   /cypress-test "Login"
   /cypress-test "Graph functionality"
   ```

## Examples

### Debug a Failing Test

```bash
# Run with headed browser and debug output
/cypress-test login.feature --headed --debug --video
```

This will:
- Open the browser so you can watch the test
- Enable verbose debug logging
- Record a video of the test execution
- Capture full stacktraces on any failures

### Run Smoke Tests with Full Capture

```bash
# Run all smoke tests with comprehensive error capture
/cypress-test @smoke --video
```

### Test a Specific Feature Against Different Environment

```bash
# Test graph functionality against staging
/cypress-test graph/graph-side-panel.feature \
  --base-url https://kiali-staging.example.com \
  --env USERNAME=testuser,PASSWD=secretpass
```

### Quick Test Without Artifacts

```bash
# Fast test run without video/screenshots for quick validation
/cypress-test @quick --no-video --no-screenshots
```

## Troubleshooting

### "Cypress not found"
Install frontend dependencies:
```bash
cd frontend && yarn install
```

### "No tests found"
Verify the test specification:
```bash
# List available feature files
find frontend/cypress/integration -name "*.feature"

# Check available tags in test files
grep -r "@" frontend/cypress/integration/**/*.feature
```

### "Cannot connect to Kiali"
Ensure Kiali is running:

**For KinD cluster setup:**
```bash
# Get the Kiali URL from the LoadBalancer service
KIALI_IP=$(kubectl get svc kiali -n istio-system -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
KIALI_URL="http://${KIALI_IP}/kiali"

# Check if Kiali is accessible
curl "${KIALI_URL}/api/status"

# Set the base URL for Cypress
export CYPRESS_BASE_URL="${KIALI_URL}"
```

**For local development:**
```bash
# Check if Kiali is accessible
curl http://localhost:3001/api/status

# Start Kiali backend if needed
make run-backend
```

### Tests fail with authentication errors
Set correct credentials:
```bash
export CYPRESS_USERNAME=admin
export CYPRESS_PASSWD=admin
export CYPRESS_AUTH_PROVIDER=my_htpasswd_provider
```

### Video recording fails
Check disk space and permissions:
```bash
# Check disk space
df -h

# Ensure videos directory is writable
mkdir -p frontend/cypress/videos
chmod 755 frontend/cypress/videos
```

## Advanced Usage

### Custom Cypress Configuration

Create a custom config file and reference it:
```bash
/cypress-test <test-spec> --config-file cypress.custom.config.ts
```

### Retry Failed Tests

```bash
# Run with retries enabled
/cypress-test <test-spec> --env retries=2
```

### Parallel Execution

```bash
# Run tests in parallel (requires Cypress Cloud or plugin)
/cypress-test <test-spec> --parallel --record --key <cypress-key>
```

## Integration with Agents

This skill can be invoked by the QE Tester agent:

```bash
@qe-tester run cypress test for login functionality with full error capture
```

The agent will handle the skill invocation and monitor progress.

## Related Documentation

- [Cypress Configuration](../../../frontend/cypress.config.ts)
- [Frontend Testing Guide](../../../frontend/cypress/README.md)
- [QE Tester Agent](../../agents/qe-tester/agent.md)
- [Kiali Development Guide](../../../AGENTS.md)
