# OpenShift Regression Testing Skill

Automated skill for executing comprehensive regression tests on OpenShift clusters.

## Quick Start

```bash
# 1. Verify OpenShift connectivity
oc status

# 2. Set required environment variables
export CYPRESS_BASE_URL=<value>                      # defaults to http://localhost:3000
export CYPRESS_USERNAME=<value>                      # defaults to jenkins, opt. kubeadmin
export CYPRESS_PASSWD=<value>                        # REQUIRED — no default
export CYPRESS_AUTH_PROVIDER=<value>                 # defaults to my_htpasswd_provider
export CYPRESS_ALLOW_INSECURE_KIALI_API=<true|false> # useful for insecure endpoints like CRC
export CYPRESS_STERN=<true|false>                    # defaults to false, set true for extended stern logging

# 3. Invoke the skill
/regression-ocp
```

Or via CLI:
```bash
./.claude/skills/regression-ocp/scripts/regression-ocp.sh
```

## Directory Structure

```
regression-ocp/
├── SKILL.md                    # Skill definition and invocation instructions
├── README.md                   # This file
├── reference.md                # Detailed reference documentation
└── scripts/
    └── regression-ocp.sh       # Main executable script
```

## Files

- **SKILL.md** - Main skill definition with frontmatter for Claude Code
- **reference.md** - Comprehensive reference documentation (original detailed spec)
- **scripts/regression-ocp.sh** - Executable bash script implementing the workflow
- **README.md** - Quick reference (this file)

## Usage

See [SKILL.md](SKILL.md) for complete usage instructions and examples.

## Related Documentation

- [Manual Workflow](../../workflows/REGRESSION_TESTING_OCP.md) - Step-by-step manual process
- [QE Tester Agent](../../agents/qe-tester/agent.md) - Agent that can invoke this skill
- [Cypress Testing Guide](../../../../frontend/cypress/README.md) - Cypress test documentation
- [OSSMC Documentation](../../../../WORKING_WITH_OSSMC.md) - OSSMC setup and usage

## Script Options

```
--dry-run           Validate setup only, don't run tests
--test-group TAG    Cypress test group tag (default: "not @multi-cluster")
--with-video        Enable video recording (disabled by default for faster execution)
--no-stern          Disable stern logging
--skip-install      Skip installation, run tests only
--help              Show help message
```

## Environment Variables

**Must be set before executing the script.** `oc status` must also return valid information.

```bash
CYPRESS_BASE_URL               Kiali URL (default: http://localhost:3000)
CYPRESS_USERNAME               OpenShift username (default: jenkins, opt. kubeadmin)
CYPRESS_PASSWD                 OpenShift password (REQUIRED — no default, script aborts without it)
CYPRESS_AUTH_PROVIDER          Auth provider (default: my_htpasswd_provider)
CYPRESS_ALLOW_INSECURE_KIALI_API  Allow insecure API (useful for CRC)
CYPRESS_STERN                  Enable stern logging (default: false, set true for extended logging)
TEST_GROUP                     Test group tag (default: "not @multi-cluster")
CYPRESS_VIDEO                  Enable video recording (default: false)
DRY_RUN                        Dry run mode (default: false)
SKIP_INSTALL                   Skip installation step (default: false)
```

## Development

The script is written in bash and designed to be:
- Idempotent - can be run multiple times safely
- Verbose - provides clear progress indicators
- Defensive - validates prerequisites and handles errors gracefully
- Modular - each step is a separate function

To modify the workflow:
1. Edit `scripts/regression-ocp.sh`
2. Update `SKILL.md` with any new options or behavior
3. Update `reference.md` if the overall workflow changes
4. Test with `--dry-run` before running full tests
