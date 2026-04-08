# Cypress QE Claude Code Plugin - Comprehensive Implementation Plan

## Executive Summary

Build a **Claude Code plugin** that automates Cypress test debugging for Kiali with focus on **autonomous code tracing and root cause analysis**. The plugin will be:

1. **Repository plugin** (`.claude/` in Kiali repo) for immediate use
2. **Global plugin** (installable to `~/.claude/plugins/`) for team/community sharing
3. **Multiple invocable skills** (`/cypress-run`, `/cypress-analyze`, `/cypress-debug`) that users can call

The plugin traces through BDD feature files + step definitions, analyzes screenshots, identifies patterns, and **auto-applies high-confidence fixes (>90%)**.

**Key Metrics:**
- Reduce debugging time from ~20 min to <5 min per failure
- Auto-fix 90%+ of high-confidence issues
- Identify patterns across multiple failures
- Zero external dependencies
- Installable as global skill for reuse

**Scope:** 3 phases + plugin packaging, 28-40 hours total
- Phase 1: MVP commands + skills - 8-12 hrs
- Phase 2: Quick analysis skill - 6-10 hrs  
- Phase 3: Deep debugging skill + agent - 14-18 hrs
- Packaging: Repository → Global plugin - 3-5 hrs

---

## Problem Statement

**Your Pain Point:** Understanding root cause takes forever

Currently debugging test failures requires:
1. ✓ Run tests manually (`yarn cypress:run:*`)
2. ✓ Parse JUnit XML to find failures
3. ✓ Correlate failures to screenshots
4. **✗ SLOW:** Trace through BDD feature files and step definitions (10-15 min)
5. **✗ SLOW:** Analyze screenshots + code + error messages (5-10 min)
6. **✗ SLOW:** Manually apply fixes (5 min)

**Total:** ~20-30 minutes per failure

**Goal:** Automate steps 4-6 (trace → analyze → fix) to <5 minutes

---

## Claude Code Plugin Architecture

### Plugin Structure

```
Repository Phase (Kiali repo)
  .claude/
  ├── .claude-plugin/
  │   └── plugin.json                   # Plugin metadata
  ├── skills/
  │   └── cypress-qe/
  │       ├── SKILL.md                  # Main plugin definition
  │       ├── commands/
  │       │   ├── cypress-run.md        # /cypress-run skill
  │       │   ├── cypress-status.md     # /cypress-status skill
  │       │   └── cypress-analyze.md    # /cypress-analyze skill
  │       ├── agents/
  │       │   └── cypress-debugger.md   # Deep debugging + auto-fix
  │       ├── docs/
  │       │   ├── PATTERNS.md           # Pattern library
  │       │   └── README.md             # User guide
  │       └── references/
  │           └── cypress-infrastructure.md  # Test setup reference
  └── CLAUDE.md                         # Update: Cypress plugin section

Global Phase (for sharing)
  ~/.claude/plugins/cypress-qe/
  ├── plugin.json
  ├── skills/
  └── docs/
  (Same structure, ready for distribution)
```

### 3-Tier System

**Tier 1: Skills (User-Invocable)**
```
/cypress-run [tag]        → Execute tests (Skill definition)
/cypress-status           → Display results (Skill definition)
/cypress-analyze [test]   → Quick analysis (Skill definition)
/cypress-debug [test]     → Deep debugging (Skill definition - launches agent)
```

**Tier 2: Agents (Autonomous Workflows)**
```
cypress-debugger          → Deep tracing + auto-fix (Agent)
```

**Tier 3: Data Access**
```
Built-in tools: Bash, Read, Grep, Glob, Edit
(No custom MCP server needed)
```

### Why This Design

- **Skills** = User-invocable commands that work in Claude Code
- **Plugin.json** = Metadata for Claude Code to discover and manage the plugin
- **SKILL.md** = Main plugin definition with description and trigger conditions
- **Agents** = Autonomous workflows for complex tasks
- **Built-in tools** = No external dependencies, works immediately
- **Global plugin support** = Can be installed and shared with others

---

## Components

### Phase 1: Commands (MVP)

#### Command: `/cypress-run [tags|category]`

**Purpose:** Execute Cypress tests with simple interface

**Usage Examples:**
```
/cypress-run core                    # Run default core tests
/cypress-run @core-1 headless junit # Headless with JUnit XML
/cypress-run @ambient                # Ambient mesh tests
/cypress-run multi-cluster           # Multi-cluster tests
```

**Behavior:**
1. Parse arguments (tag, category, or file path)
2. Map to existing yarn scripts:
   - `core` → `yarn cypress:run:core-1 && yarn cypress:run:core-2`
   - `@ambient` → `yarn cypress:run:ambient`
   - `multi-cluster` → `yarn cypress:run:multi-cluster`
   - `@multi-primary` → `yarn cypress:run:multi-primary`
3. Execute in background
4. Monitor and report results
5. Display summary:
   ```
   ✓ Tests complete: 42 passed, 3 failed
   Run /cypress-status for details
   ```

**Supported Tags (from package.json):**
- `@core-1`, `@core-2` - Core tests
- `@ambient` - Ambient mesh
- `@multi-cluster` - Multi-cluster
- `@multi-primary` - Multi-primary
- `@tracing` - Tracing tests
- `@ai-chatbot` - AI chatbot
- `@waypoint` - Waypoint tests
- `@external-kiali` - External Kiali

---

#### Command: `/cypress-status`

**Purpose:** Show latest test results

**Behavior:**
1. Find latest JUnit XML: `frontend/cypress/results/*.xml`
2. Parse and extract:
   - Total tests, passed, failed, skipped
   - Test duration
   - Failure details (error message, stack trace)
   - Screenshot path
3. Display formatted summary:
   ```
   Last Run: 2026-04-08 14:32:15
   Suite: @core-1 or @core-2
   Duration: 12m 34s
   
   Results:
   ✓ Passed: 42 tests
   ✗ Failed: 3 tests
   ⊘ Skipped: 0 tests
   
   Failures:
   1. App Details › Traffic Information Display
      Error: Timed out retrying after 40000ms: Expected to find element '#traffic-tab'
      Screenshot: cypress/screenshots/core/app_details/Traffic_Information_Display.png
      
   2. Workload Logs › Severity Filtering
      Error: cy.getBySel() failed - element not found: severity-filter
      Screenshot: cypress/screenshots/core/workload_logs/Severity_Filtering.png
   
   Next: /cypress-analyze <test-name> or launch cypress-debugger agent
   ```

---

#### Command: `/cypress-analyze [test-name]`

**Purpose:** Quick failure analysis with pattern matching

**Behavior:**
1. Parse test name from argument (or list failures if empty)
2. Find matching failure in JUnit XML
3. Gather context:
   - Error message and stack trace
   - Feature file and line number
   - Step definition code
   - Screenshot (if available)
4. Match against 6 known patterns (see Pattern Library)
5. Generate quick fix suggestion
6. Display:
   ```
   Test: App Details › Traffic Information Display
   File: cypress/integration/featureFiles/app_details.feature:45
   Step: cypress/integration/common/app_details.ts:78
   
   Error: Timed out retrying after 40000ms: Expected to find element '#traffic-tab'
   
   Screenshot Analysis:
   - Loading spinner visible (#loading_kiali_spinner)
   - Traffic tab container exists but button not rendered
   - React component appears incomplete
   
   Pattern Match: Loading State Race Condition (95% confidence)
   
   Root Cause:
   Test tries to click Traffic tab before React fully mounted
   
   Quick Fix:
   Add before the click:
     ensureKialiFinishedLoading();
     cy.waitForReact();
   
   File: cypress/integration/common/app_details.ts:75
   
   For detailed debugging: Launch cypress-debugger agent
   ```

---

### Phase 2: Quick Analysis with Patterns

**Pattern Library (6 Common Failures)**

The `/cypress-analyze` command uses this pattern library:

#### Pattern 1: Loading State Race Condition
- **Frequency:** 67% of failures
- **Symptom:** Timeout after 40s, element not found
- **Evidence in Screenshot:** `#loading_kiali_spinner` visible
- **Root Cause:** Missing `ensureKialiFinishedLoading()` call
- **Fix:** Add `ensureKialiFinishedLoading()` before assertions
- **Confidence:** 95%
- **Reference:** `cypress/integration/common/transition.ts`

#### Pattern 2: React Component Not Ready
- **Frequency:** 15% of failures
- **Symptom:** Element exists but not interactive
- **Root Cause:** Missing `cy.waitForReact()`
- **Fix:** Add `cy.waitForReact()` after navigation
- **Confidence:** 90%
- **Reference:** `cypress/support/commands.ts`

#### Pattern 3: Multi-Cluster Health Timeout
- **Frequency:** 10% of failures
- **Symptom:** 5-minute timeout in @multi-cluster tests
- **Root Cause:** Secondary cluster slow to become ready
- **Fix:** Increase timeout to 10 min, check cluster health
- **Confidence:** 85%
- **Tags:** @multi-cluster, @multi-primary

#### Pattern 4: Session/Cookie Issues
- **Frequency:** 5% of failures
- **Symptom:** Auth errors, kiali-token-aes missing
- **Root Cause:** Session expired, cookie not set
- **Fix:** Check `cy.session()` and `/api/status` calls
- **Confidence:** 80%
- **Reference:** `cypress/plugins/setup.ts`

#### Pattern 5: Network Intercept Missing
- **Frequency:** 2% of failures
- **Symptom:** Unexpected API response, timeout
- **Root Cause:** `cy.intercept()` not configured
- **Fix:** Add intercept for API endpoint
- **Confidence:** 75%

#### Pattern 6: Selector Changed
- **Frequency:** 1% of failures
- **Symptom:** `cy.getBySel()` fails immediately
- **Root Cause:** `data-test` attribute removed/renamed
- **Fix:** Update selector or add `data-test` to component
- **Confidence:** 70%

---

### Phase 3: Deep Debugging Agent with Auto-Fix

**Agent: `cypress-debugger`**

**When to Use:**
- /cypress-analyze result isn't clear
- Multiple failures need investigation
- Need to trace through complex code paths
- Want automatic fix application

**7-Phase Workflow:**

##### Phase 1: Results Parsing (5 min)
- Locate latest JUnit XML in `frontend/cypress/results/`
- Extract all failures with:
  - Test name and feature file
  - Error message and stack trace
  - Screenshot path
  - Duration and retry count

##### Phase 2: Screenshot Analysis (10 min)
- Read screenshot using Read tool (PNG support)
- Describe UI state in detail:
  - Is loading spinner visible?
  - Are expected elements present?
  - What error messages visible?
  - Layout/rendering issues?
- Correlate screenshot state with error message

##### Phase 3: Code Tracing (15 min)
- **Find feature file:**
  ```bash
  grep -r "Scenario.*Test Name" cypress/integration/featureFiles/
  ```
- **Extract scenario steps:** Parse Given/When/Then
- **Find step definitions:**
  ```bash
  grep -r "Given.*user opens.*app" cypress/integration/common/
  grep -r "Then.*user sees.*traffic" cypress/integration/common/
  ```
- **Trace execution path:**
  - Read step definition files
  - Identify selectors and timeouts
  - Check for cy.get(), cy.getBySel(), cy.intercept()
  - Find critical code section in stack trace

##### Phase 4: Pattern Matching (10 min)
- Match against 6 patterns in Pattern Library
- Score confidence (70-100%)
- If multiple matches, rank by likelihood

##### Phase 5: Root Cause Analysis (5 min)
- Synthesize findings:
  - Screenshot shows X
  - Error message says Y
  - Code does Z at line N
  - Pattern matches: ABC
- Determine root cause with confidence level
- Example: "95% confidence: Loading state race condition"

##### Phase 6: Fix Generation (10 min)
- **High confidence (90%+):**
  - Generate exact code snippet
  - Provide file:line reference
  - Include necessary imports
  - Match existing code style
  
- **Medium confidence (70-89%):**
  - Generate primary fix
  - Provide 1-2 alternatives
  - Rank by likelihood

- **Low confidence (<70%):**
  - Provide multiple suggestions
  - Flag as "needs investigation"
  - Don't generate code

##### Phase 7: Auto-Apply Fix (Variable)
- **Confidence 90%+:**
  - ✅ Auto-apply using Edit tool
  - Display: "Fix applied automatically"
  - Suggest re-run to verify

- **Confidence 70-89%:**
  - Show fix and ask: "Apply? (y/n)"
  - Wait for user decision
  - Apply only if approved

- **Confidence <70%:**
  - ❌ Don't apply
  - Show suggestions only
  - Ask user to choose

**Example Output:**

```markdown
# Cypress Test Debugging Report

## Summary
- Failure Analyzed: App Details › Traffic Information Display
- Pattern Matched: Loading State Race Condition
- Confidence: 95%
- Action: Auto-applying fix

## Analysis

**Location:**
- Feature: cypress/integration/featureFiles/app_details.feature:45
- Step: cypress/integration/common/app_details.ts:78

**Error:**
Timed out retrying after 40000ms: Expected to find element '#traffic-tab'

**Screenshot Analysis:**
[Visual description]
- Loading spinner visible: YES (#loading_kiali_spinner)
- Expected element present: NO (#traffic-tab)
- React component state: INCOMPLETE
- Assessment: Race condition, component not fully mounted

**Code Context:**
```typescript
// cypress/integration/common/app_details.ts:75-82
Then('user sees traffic information', () => {
  openTab('Traffic');  // ← FAILURE HERE
  cy.getBySel('traffic-chart').should('be.visible');
});

// cypress/integration/common/transition.ts:37
export const openTab = (tab: string): void => {
  cy.get('#basic-tabs').should('exist').contains(tab).click();
};
```

**Pattern Match:** Loading State Race Condition (95% confidence)

**Root Cause:**
Test clicks Traffic tab before React component fully mounts. Loading spinner visible in screenshot confirms component still rendering.

**Applied Fix:**
```typescript
// cypress/integration/common/app_details.ts:75-82
import { ensureKialiFinishedLoading } from './transition';

Then('user sees traffic information', () => {
  ensureKialiFinishedLoading();  // ← ADDED
  cy.waitForReact();              // ← ADDED
  openTab('Traffic');
  cy.getBySel('traffic-chart').should('be.visible');
});
```

**Status:** ✓ Fix applied to cypress/integration/common/app_details.ts

**Next Step:**
Verify with: /cypress-run @core-1

**Expected:** Test should pass, traffic tab clickable immediately
```

---

## Implementation Timeline

### Phase 1: MVP - Plugin Scaffolding + Basic Skills (8-12 hours)

**Deliverables:**
- Claude Code plugin structure with `plugin.json`
- Main `SKILL.md` for cypress-qe plugin
- `/cypress-run` skill (execute tests)
- `/cypress-status` skill (check results)
- Plugin documentation
- No external dependencies

**Critical Files to Create:**
```
.claude/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── cypress-qe/
│       ├── SKILL.md
│       ├── commands/
│       │   ├── cypress-run.md
│       │   └── cypress-status.md
│       ├── docs/
│       │   └── README.md
│       └── references/
│           └── cypress-infrastructure.md
└── CLAUDE.md (update with plugin section)
```

**Claude Code Plugin Specifics:**
- `plugin.json`: Name, version, description, author
- `SKILL.md`: Main skill definition with markdown + YAML frontmatter
- `commands/*.md`: Individual skill definitions for each command
- Skills use YAML frontmatter:
  ```yaml
  ---
  description: "What this command does"
  argument-hint: "[optional-args]"
  allowed-tools: ["Bash", "Read", "Grep"]
  ---
  # Command Documentation
  ```

**Success Criteria:**
- Plugin discovered by Claude Code
- Can invoke: `/cypress-run core`
- Can invoke: `/cypress-status`
- Help text displays for each skill
- Results display with failure list
- No errors or missing dependencies

---

### Phase 2: Quick Analysis Skill (6-10 hours)

**Deliverables:**
- `/cypress-analyze` skill
- 6-pattern library (documented)
- Screenshot reading capability
- Pattern matching logic

**Critical Files to Create:**
```
.claude/skills/cypress-qe/
├── commands/
│   ├── cypress-analyze.md       # /cypress-analyze skill
│   └── cypress-debug.md         # /cypress-debug skill (launches agent)
├── docs/
│   └── PATTERNS.md              # Pattern library documentation
└── references/
    └── cypress-infrastructure.md  # Updated with pattern reference
```

**Claude Code Plugin Specifics:**
- Skill definitions with pattern matching logic
- Ability to read PNG screenshots using Read tool
- Pattern library as reference material in docs/
- Skills can launch agents via `cypress-debugger` invocation

**Success Criteria:**
- `/cypress-analyze app_details` analyzes failure in <30s
- Identifies correct pattern 80%+ of time
- Suggests actionable fix with confidence score
- Reads and describes screenshots
- Skills are discoverable and callable

---

### Phase 3: Deep Debugging Agent + Auto-Fix Skill (14-18 hours)

**Deliverables:**
- `/cypress-debug` skill that launches autonomous agent
- `cypress-debugger` agent (Sonnet model)
- 7-phase workflow implementation
- Confidence-based auto-fix logic
- Code tracing through feature files + step definitions
- Screenshot analysis with visual description

**Critical Files to Create:**
```
.claude/skills/cypress-qe/
├── commands/
│   └── cypress-debug.md         # /cypress-debug skill → launches agent
└── agents/
    └── cypress-debugger.md      # Autonomous debugging agent (Sonnet)
```

**Claude Code Plugin Specifics:**
- Skill definition for `/cypress-debug` that invokes autonomous agent
- Agent uses Sonnet model for complex reasoning
- Agent has access to: Bash, Read, Grep, Glob, Edit tools
- Agent can read screenshots as PNG and analyze visually
- Agent can apply fixes using Edit tool
- Confidence-based decision logic:
  - 90%+: Auto-apply fix
  - 70-89%: Ask user approval
  - <70%: Suggest alternatives

**Success Criteria:**
- `/cypress-debug app_details` launches agent
- Agent completes in <5 minutes
- Identifies root cause with 80%+ confidence
- Auto-applies 90%+ of high-confidence fixes
- Asks for approval on medium confidence (70-89%)
- Reports correctly on low confidence (<70%)
- Fixes are correct and don't break tests

---

## File Structure

### Phase 1: Repository Plugin (Kiali Repo)

```
/Users/pmarek/work/github.com/scriptingShrimp/kiali/.claude/

.claude-plugin/
└── plugin.json
    {
      "name": "cypress-qe",
      "version": "1.0.0",
      "description": "Cypress QE automation with test execution, analysis, debugging, and auto-fix",
      "author": { "name": "Pavel Marek", "email": "..." }
    }

skills/
└── cypress-qe/
    ├── SKILL.md
    │   ---
    │   name: cypress-qe
    │   description: "Automate Cypress test execution, analysis, and debugging with confidence-based auto-fix"
    │   version: 1.0.0
    │   ---
    │
    │   # Cypress QE Testing Toolkit
    │
    │   Automate Cypress regression testing, failure analysis, and debugging.
    │   Trace through test code, analyze screenshots, identify patterns, auto-apply fixes.
    │
    │   Usage: /cypress-run core, /cypress-analyze app_details, /cypress-debug
    │   Launch agents: cypress-debugger
    │
    ├── commands/
    │   ├── cypress-run.md         # /cypress-run skill definition
    │   ├── cypress-status.md      # /cypress-status skill definition
    │   ├── cypress-analyze.md     # /cypress-analyze skill definition
    │   └── cypress-debug.md       # /cypress-debug skill definition (launches agent)
    │
    ├── agents/
    │   └── cypress-debugger.md    # Agent: deep debugging + auto-fix
    │
    ├── docs/
    │   ├── README.md              # How to use the plugin
    │   ├── PATTERNS.md            # Pattern library (6 patterns)
    │   └── EXAMPLES.md            # Usage examples
    │
    └── references/
        └── cypress-infrastructure.md  # Test setup + common commands

CLAUDE.md
├── Add "Cypress QE Plugin" section
└── Link to plugin documentation

settings.local.json  # Minimal config, mostly empty
```

### Phase 2: Global Plugin (For Sharing)

After repo plugin works, package for global use:

```
~/.claude/plugins/cypress-qe/

(Same structure as above)
plugin.json
skills/
  └── cypress-qe/
      ├── SKILL.md
      ├── commands/
      ├── agents/
      ├── docs/
      └── references/
```

Installation for users:
```bash
claude-code plugin install cypress-qe
# Or clone from GitHub
git clone https://github.com/kiali/claude-code-cypress-qe ~/.claude/plugins/cypress-qe
```

---

## Test Infrastructure Reference

**Key Directories:**
- Tests: `frontend/cypress/integration/featureFiles/` (53 feature files)
- Step definitions: `frontend/cypress/integration/common/` (48 files)
- Results: `frontend/cypress/results/*.xml` (JUnit XML)
- Screenshots: `frontend/cypress/screenshots/<tag>/` (organized by test category)

**Key Files:**
- Config: `frontend/cypress.config.ts`
- Reporters: `frontend/reporter-config.json`
- NPM scripts: `frontend/package.json`
- Cypress setup: `frontend/cypress/plugins/setup.ts`
- Custom commands: `frontend/cypress/support/commands.ts`

**Test Tags:**
- `@core-1`, `@core-2` - Core functionality
- `@ambient` - Ambient mesh
- `@multi-cluster` - Multi-cluster
- `@tracing` - Tracing
- `@ai-chatbot` - AI features

---

## Dependencies

**Existing (No Installation):**
- Node.js >= 20 ✓
- Yarn via corepack ✓
- Cypress 13.6.1 ✓
- @badeball/cypress-cucumber-preprocessor ✓

**New Required:**
- **NONE!** Uses only Claude Code built-in tools:
  - Bash (run commands)
  - Read (parse XML, view screenshots)
  - Grep (search files)
  - Glob (find files)
  - Edit (apply fixes)

**Installation Time:** 0 hours

---

## Success Metrics

### Phase 1 (MVP)
- ✓ Can run tests with `/cypress-run core`
- ✓ Can check status with `/cypress-status`
- ✓ Results display accurately

### Phase 2 (Analysis)
- ✓ Analyzes failure in <30 seconds
- ✓ Pattern identification >80% accurate
- ✓ Screenshots readable

### Phase 3 (Debugging + Auto-Fix) ← YOUR MAIN REQUEST
- ✓ Agent completes in <5 min
- ✓ Root cause identified with 80%+ confidence
- ✓ Auto-fixes 90%+ of high-confidence cases
- ✓ Asks approval for 70-89% confidence
- ✓ Debugging time reduced from 20 min to <5 min

---

## Claude Code Plugin Technical Details

### How Claude Code Plugins Work

**Plugin Discovery:**
- Claude Code looks for `.claude-plugin/plugin.json` in repository
- Also looks in `~/.claude/plugins/` for global plugins
- Registers all skills/commands defined in the plugin

**Skills/Commands:**
- Defined as markdown files with YAML frontmatter
- File format:
  ```yaml
  ---
  description: "What this skill does"
  argument-hint: "[args]"
  allowed-tools: ["Bash", "Read", "Grep"]
  ---
  
  # Skill Documentation
  
  Instructions for Claude on how to execute...
  ```

**Agents:**
- Defined as markdown files with agent-specific frontmatter
- File format:
  ```yaml
  ---
  name: agent-name
  description: "When to use this agent"
  model: sonnet|haiku|opus
  allowed-tools: ["Bash", "Read", "Edit"]
  ---
  
  # Agent Instructions
  
  System prompt for the autonomous agent...
  ```

**Plugin Metadata (plugin.json):**
```json
{
  "name": "cypress-qe",
  "version": "1.0.0",
  "description": "Cypress QE testing automation",
  "author": { "name": "Name", "email": "email" }
}
```

### How Users Invoke the Plugin

**Repository Plugin (Kiali repo):**
```
# Available immediately in the Kiali Claude Code session
/cypress-run core
/cypress-status
/cypress-analyze app_details
/cypress-debug app_details     # Launches agent
```

**Global Plugin:**
```
# After installation to ~/.claude/plugins/cypress-qe
/cypress-run core              # Works in any project
/cypress-status
/cypress-analyze app_details
/cypress-debug app_details     # Works if .claude/settings enables it
```

### Phase 5: Packaging for Global Use (3-5 hours)

After repo plugin works:

1. **Create GitHub repo** (optional)
   - `kiali/claude-code-cypress-qe`
   - Distribution for team/community

2. **Create installation guide**
   - How to install globally
   - Configuration instructions
   - Examples for different projects

3. **Update plugin.json**
   - Add repository URL
   - Add license
   - Add homepage link

4. **Test on another machine/project**
   - Verify plugin installs
   - Verify skills work
   - Verify agents execute correctly

---

## Next Steps

1. **Review this plan** - Does it match your vision of a Claude Code plugin?
2. **Ask clarifying questions** - Anything unclear about plugin structure?
3. **Request changes** - Any modifications needed before implementation?
4. **Approve** - Ready to implement Phase 1?

---

## Notes for Implementation

### What We're NOT Building
- ❌ Custom MCP server (not needed)
- ❌ External npm packages (not needed)
- ❌ Web UI (Claude Code UI is enough)
- ❌ CI integration hooks (can add later)

### What We ARE Building
- ✅ 3 commands for running/checking/analyzing tests
- ✅ 1 agent for deep debugging and auto-fix
- ✅ Confidence-based auto-fix logic
- ✅ Code tracing through test infrastructure
- ✅ Screenshot analysis and description
- ✅ Pattern library with 6 common failure types

### Simplicity First
- Start with Bash commands for test execution
- Use Read tool for XML parsing and screenshots
- Use Grep for searching feature files and step definitions
- Keep it simple, iterate if needed

