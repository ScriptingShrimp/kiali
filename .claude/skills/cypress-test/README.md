# Cypress Test Runner Skill

Automated skill for running specific Cypress tests with comprehensive error capture and full stacktrace collection.

## Quick Start

```bash
# Run a specific feature file
/cypress-test graph/graph-side-panel.feature

# Run tests with a tag
/cypress-test @smoke --video

# Debug a failing test
/cypress-test login.feature --headed --debug
```

Or via CLI:
```bash
./.claude/skills/cypress-test/scripts/cypress-test.sh <test-spec> [options]
```

## What This Skill Does

This skill provides comprehensive test execution with:

- **Full Stacktrace Capture** - Captures complete error stacktraces from all test failures
- **Video Recording** - Records test execution (optional, disabled by default for speed)
- **Screenshot Capture** - Automatically captures screenshots on test failures
- **Browser Console Logs** - Collects all browser console output
- **Detailed Reporting** - Generates comprehensive test reports with all artifacts organized
- **Flexible Test Selection** - Run by file, tag, or test name

## Directory Structure

```
cypress-test/
├── SKILL.md                    # Skill definition and comprehensive documentation
├── README.md                   # This file - quick reference
└── scripts/
    └── cypress-test.sh         # Main executable script
```

## Common Use Cases

### Debug a Failing Test
```bash
/cypress-test login.feature --headed --debug --video
```
Opens the browser, enables verbose logging, and records the test execution.

### Run Smoke Tests with Error Capture
```bash
/cypress-test @smoke
```
Runs all smoke tests and captures full stacktraces on any failures.

### Test Against Different Environment
```bash
/cypress-test @core-1 --base-url https://kiali-staging.example.com
```

### Quick Test Without Artifacts
```bash
/cypress-test @quick --no-video --no-screenshots
```

## Key Features

### Stacktrace Capture
- Extracts complete error stacktraces from Cypress output
- Includes assertion errors, Cypress errors, and runtime errors
- Saves all stacktraces to `stacktraces.txt` for easy analysis

### Organized Artifacts
All test artifacts are saved in a timestamped directory:
```
test-results-YYYYMMDD-HHMMSS/
├── test-report.txt              # Summary report
├── stacktraces.txt              # Full stacktraces
├── logs/
│   └── cypress-log.txt          # Complete Cypress output
├── screenshots/                 # Failure screenshots
└── videos/                      # Test execution videos (if enabled)
```

### Flexible Test Specifications

The skill accepts multiple test specification formats:

1. **Feature file path**: `graph/graph-side-panel.feature`
2. **Cucumber tag**: `@smoke`, `"@core-1 or @core-2"`, `"not @multi-cluster"`
3. **Test name**: `"Login functionality"`

## Options

```
--video               Enable video recording
--headed              Run in headed mode (open browser)
--browser <name>      Browser to use (chrome, firefox, edge, electron)
--base-url <url>      Base URL for tests
--env <vars>          Environment variables (KEY=VALUE,KEY2=VALUE2)
--tag <tag>           Run tests with specific tag
--output-dir <dir>    Custom output directory
--debug               Enable debug mode (verbose logging)
--help                Show help message
```

## Environment Variables

```bash
export CYPRESS_BASE_URL=http://localhost:3001    # Kiali URL
export CYPRESS_USERNAME=admin                    # Username
export CYPRESS_PASSWD=admin                      # Password
export CYPRESS_AUTH_PROVIDER=my_htpasswd_provider
export CYPRESS_VIDEO=true                        # Enable video
export CYPRESS_BROWSER=chrome                    # Browser choice
```

## Prerequisites

- Node.js >= 24.0.0
- Yarn package manager
- Cypress installed (`cd frontend && yarn install`)
- Running Kiali instance (for integration tests)

## Examples

### Run All Core Tests
```bash
/cypress-test "@core-1 or @core-2"
```

### Debug Specific Scenario
```bash
/cypress-test "user can login successfully" --headed --debug
```

### Test with Video in Chrome
```bash
/cypress-test @smoke --video --browser chrome
```

### Custom Environment
```bash
/cypress-test graph/graph-side-panel.feature \
  --base-url https://kiali.example.com \
  --env USERNAME=testuser,PASSWD=secret
```

## Output

The skill provides:

1. **Real-time console output** showing test execution progress
2. **Test report** with summary and artifact locations
3. **Full stacktraces** for all failures
4. **Organized artifacts** in timestamped directory
5. **Exit code** indicating success (0) or failure (non-zero)

## Integration

This skill can be invoked by:

- **Direct command**: `/cypress-test <spec>`
- **CLI script**: `scripts/cypress-test.sh <spec>`
- **QE Tester Agent**: `@qe-tester run cypress test for <spec>`

## Troubleshooting

### Cypress not found
```bash
cd frontend && yarn install
```

### Cannot connect to Kiali
```bash
# Start backend
make run-backend

# Or verify URL
curl http://localhost:3001/api/status
```

### Authentication errors
```bash
export CYPRESS_USERNAME=admin
export CYPRESS_PASSWD=admin
export CYPRESS_AUTH_PROVIDER=my_htpasswd_provider
```

### No tests found
```bash
# List available features
find frontend/cypress/integration -name "*.feature"

# Check available tags
grep -r "@" frontend/cypress/integration/**/*.feature
```

## Related Documentation

- [SKILL.md](SKILL.md) - Complete documentation with all options and examples
- [Cypress Configuration](../../../frontend/cypress.config.ts)
- [Frontend Testing Guide](../../../frontend/cypress/README.md)
- [QE Tester Agent](../../agents/qe-tester/agent.md)
- [Kiali Development Guide](../../../AGENTS.md)

## Script Location

The executable script is located at:
```
.claude/skills/cypress-test/scripts/cypress-test.sh
```

Can be run directly from anywhere:
```bash
/path/to/kiali/.claude/skills/cypress-test/scripts/cypress-test.sh <test-spec>
```
