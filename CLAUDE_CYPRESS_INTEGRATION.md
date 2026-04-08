# Integrating Claude Code with Cypress Regression Suites

> **Research date:** April 2026  
> **Sources:** Cypress official blog, Anthropic docs, ITNEXT, GoPenAI/Medium, GitHub projects, developer blogs, and community resources.

---

## Overview

The Claude + Cypress integration landscape has evolved rapidly in 2025–2026, with approaches ranging from first-party Cypress features powered by AI, to Claude's own agentic infrastructure, to community-built tooling. This document covers each distinct approach, its mechanics, tradeoffs, and links to relevant resources.

---

## Approach 1: AGENTS.md / CLAUDE.md Context Files for AI-Assisted Test Authoring

**Sources:** [cypress-io/cypress PR #33429](https://github.com/cypress-io/cypress/pull/33429), [Claude Lab CLAUDE.md Guide](https://claudelab.net/en/articles/claude-code/claude-md-agents-md-complete-guide)

### What It Is

Cypress itself merged a comprehensive set of `AGENTS.md` and `CLAUDE.md` files into their monorepo in March 2026 ([PR #33429](https://github.com/cypress-io/cypress/pull/33429), released in Cypress 15.12.0). The approach structures AI agent guidance at three levels: root, workspace, and per-package — 117 files total with 2,945 additions.

This is not a tool integration. It is a **context engineering pattern** that tells Claude Code (and other AI agents like Codex CLI and Cursor) exactly how to work in the repository: what commands to run, which testing conventions to follow, and what *not* to do.

### File Hierarchy

```
kiali/                          ← Root AGENTS.md + CLAUDE.md
├── frontend/
│   ├── AGENTS.md               ← Frontend workspace context
│   └── CLAUDE.md               ← Thin wrapper that imports AGENTS.md
├── cypress/
│   └── AGENTS.md               ← Cypress-specific conventions
└── ...
```

`CLAUDE.md` files are thin wrappers that import `AGENTS.md` so Claude Code finds them as it walks upward from the working directory. `AGENTS.md` contains the substantive content.

### Cypress-Specific Conventions the Files Encode

```markdown
# Test Runner Conventions for AI Agents

## Command Rules
- No watch/file-watcher commands — agents run once and read results
- No bare full-suite test runs for large packages
- Never use `cypress:open` — use `cypress:run --spec` instead
- Always target specific specs: `cypress:run -- --spec "cypress/e2e/auth/**"`

## Test Runner Selection by Package
- Vitest: `test --`
- Mocha: `test-unit/test-integration --`
- Jest: `--testPathPattern`
- Cypress CT: `cypress:run:ct -- --spec`
```

### Practical Template for Your Own Repo

```markdown
# CLAUDE.md — Cypress Test Conventions

## Overview
See AGENTS.md for authoritative content.

## Quick Start for AI Agents
- All E2E specs live in `cypress/e2e/`
- Use `npm run cypress:run -- --spec "cypress/e2e/auth.cy.ts"` for targeted runs
- Never run the full suite; always target a spec or glob
- Use `data-cy` attributes for element selection
- Page Objects live in `cypress/support/pages/`
- Custom commands are in `cypress/support/commands.ts`
- Tests follow the Arrange-Act-Assert pattern
- No hardcoded waits (`cy.wait(3000)`) — use `cy.intercept()` aliases
```

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| No runtime cost — pure documentation | Requires human maintenance as repo evolves |
| Works with any AI agent (Claude, Codex, Cursor) | Quality of AI output still depends on quality of context files |
| Prevents AI from running destructive commands | Does not generate tests; only guides generation |
| Encodes team conventions permanently | Needs to be added to every package that needs AI guidance |

---

## Approach 2: Claude Code + GitHub Actions CI Pipeline for Automatic Test Generation

**Sources:** [SmartScope Blog](https://smartscope.blog/en/ai-development/github-actions-automated-testing-claude-code-2025/), [Claude Lab Guide](https://claudelab.net/en/articles/api-sdk/claude-api-github-actions-cicd-ai-automation-guide), [Anthropic claude-code-action](https://github.com/anthropics/claude-code-action), [Skills Playground](https://skillsplayground.com/guides/claude-code-github-actions/)

### What It Is

A CI/CD pipeline that automatically invokes Claude Code on every PR to generate, run, and report on tests for changed files. Anthropic provides the official `anthropics/claude-code-action` GitHub Action for non-interactive execution.

### Architecture

```
PR opened/synchronized
    │
    ├─► Extract changed files (git diff)
    │
    ├─► Claude Code generates Cypress specs for changed files
    │
    ├─► Run generated specs (cypress:run --spec)
    │
    └─► Post coverage report as PR comment
```

### CLAUDE.md for Test Generation

Create `CLAUDE.md` in the repo root with generation rules:

```markdown
# Claude Code Automated Test Generation

## Test Framework
- E2E: Cypress
- Spec location: cypress/e2e/
- Support files: cypress/support/

## Generation Rules
- Generate positive, negative, and boundary value tests for each changed flow
- Use data-cy selectors exclusively; never use CSS class selectors
- Target 80%+ coverage of user-visible interactions
- Use cy.intercept() for network stubbing; never use cy.wait(number)
- Follow Page Object Model: page objects in cypress/support/pages/
- Placeholders for secrets: use Cypress.env()
- No bare cy.wait() — alias intercepts and use cy.wait('@alias')
```

### GitHub Actions Workflow

```yaml
name: Claude Code - Cypress Test Generation
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  generate-and-run-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Identify changed frontend files
        id: changed
        run: |
          FILES=$(git diff --name-only HEAD~1 | grep -E '\.(tsx?|jsx?)$' | tr '\n' ' ')
          echo "files=$FILES" >> $GITHUB_OUTPUT

      - name: Generate Cypress specs with Claude Code
        uses: anthropics/claude-code-action@beta
        with:
          prompt: |
            Generate comprehensive Cypress E2E specs for the following changed files:
            ${{ steps.changed.outputs.files }}
            
            Follow conventions in CLAUDE.md.
            Save generated specs to cypress/e2e/generated/.
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Run generated specs
        run: |
          npx cypress run \
            --spec "cypress/e2e/generated/**/*.cy.ts" \
            --record \
            --key ${{ secrets.CYPRESS_RECORD_KEY }}

      - name: Post results to PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '🤖 **AI Cypress Tests Generated and Executed**\nCheck Cypress Cloud for results.'
            })
```

### Production Best Practices (Claude Lab)

1. **Send only diffs** — never entire codebases; controls token costs
2. **Cache aggressively** — use Prompt Caching to reduce costs 70–90%
3. **Run AI reviews asynchronously** — don't block core CI pipeline
4. **Fail gracefully** — retry logic for rate limits; don't fail the build on AI errors

### Real-World Results

OpenObserve scaled from 380 to 700+ tests using Claude Code in CI, reducing flaky tests by 85%, with feature analysis time dropping from 45–60 min to 5–10 min.

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| Fully automated — no human intervention per PR | Generated tests need quality review (happy-path bias) |
| Works with existing GitHub Actions infrastructure | API costs accumulate at scale |
| Can target only changed files (efficient) | Hallucinations are possible — tests may not reflect real UI |
| Integrates with Cypress Cloud for results visibility | Requires solid CLAUDE.md conventions or output quality suffers |

---

## Approach 3: Multi-LLM Test Generation Framework (Open Source)

**Sources:** [GoPenAI / Medium](https://blog.gopenai.com/multi-llm-test-automation-generate-cypress-and-playwright-tests-with-chatgpt-claude-or-gemini-04aedc297da1), [GitHub: aiqualitylab/ai-natural-language-tests](https://github.com/aiqualitylab/ai-natural-language-tests)

### What It Is

An open-source Python framework (`ai-natural-language-tests`, v3.3) that generates full Cypress or Playwright spec files from a single plain-English description. Claude is one of three supported LLM providers (OpenAI, Anthropic, Google). The framework uses LangChain + LangGraph for a structured five-step pipeline.

### Five-Step LangGraph Pipeline

```
1. Fetch page HTML           (puppeteer/httpx)
      ↓
2. Analyze selectors         (LLM extracts stable data-cy, aria-*, text anchors)
      ↓
3. Check pattern history     (vector store of past generated specs)
      ↓
4. Generate test spec        (LLM — Cypress or Playwright)
      ↓
5. Run test (optional)       (cypress run / playwright test)
```

### Usage

```bash
# Generate with Claude (Anthropic)
python qa_automation.py \
  "Test login with valid credentials" \
  --url https://myapp.com/login \
  --llm anthropic

# Generate Playwright instead of Cypress
python qa_automation.py \
  "Test checkout flow for logged-in user" \
  --url https://myapp.com/checkout \
  --llm anthropic \
  --framework playwright
```

### Environment Setup

```bash
# .env
OPENAI_API_KEY=sk-...         # default provider
ANTHROPIC_API_KEY=sk-ant-...  # for Claude

# Install Claude provider
pip install langchain-anthropic
```

### Claude's Characteristics vs. Other Models

From the author's testing:
- **Claude** — more thorough with edge cases; adds assertions not explicitly requested (e.g., asserting error messages disappear after success); infers broader test intent from the requirement
- **ChatGPT** — compact, pattern-heavy, closely follows framework conventions
- **Gemini** — clean output but may structure tests differently (e.g., prefers `test.describe` blocks)

### Docker Usage

```bash
docker compose run --rm test-generator \
  "Test login" \
  --url https://example.com \
  --llm anthropic
```

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| Provider-agnostic; graceful fallback to OpenAI | Requires Python + LangChain stack alongside your JS project |
| Vector store learns patterns from past generations | External dependency; another system to maintain |
| Can compare output across Claude/GPT/Gemini | Docker adds infra complexity |
| Open source; free to self-host | LLM selector inference is still imperfect without live DOM |

---

## Approach 4: LLM-Powered Self-Healing (Custom Build with Claude Sonnet)

**Sources:** [ITNEXT article by Alex Nebot Oller](https://itnext.io/self-healing-e2e-tests-reducing-manual-maintenance-efforts-using-llms-db35104a7627), [GitHub: agune15/self-healing-e2e-tests-prototype](https://github.com/agune15/self-healing-e2e-tests-prototype)

### What It Is

A custom prototype using **Claude Sonnet 3.5** (now generalized to also support Gemini) to automatically analyze failing Cypress tests, propose exact code patches, apply them, and open a GitLab/GitHub merge request for human review. Conceived and built by a QA automation engineer tired of manual test maintenance loops.

### How It Works

```
Cypress test run fails
        │
        ├─► Capture: error message + test code + file path
        │
        ├─► Render: HTML snapshot of the app at failure time
        │
        ├─► Build prompt: test context + HTML + code + helper deps
        │
        ├─► Claude Sonnet analyzes: diagnoses root cause
        │
        ├─► Claude returns JSON: [{
        │     "isFixable": "YES",
        │     "explanation": "...",
        │     "fixes": [{
        │       "file": "...",
        │       "function": "...",
        │       "before": "cy.typeInput(...)",
        │       "after": "cy.typeAutocomplete(...)"
        │     }]
        │   }]
        │
        ├─► Patch script: validates before-code matches exactly, applies diff
        │
        └─► Git: creates branch + opens MR/PR for human review
```

### Prompt Structure (Key Sections)

1. **Test Context** — title, error message, file path
2. **Code and Dependency Context** — failing function + helpers
3. **HTML Validation Messages** — frontend validation errors parsed from DOM
4. **HTML Snapshot** — rendered HTML at failure time
5. **Instructions** — structured reasoning strategies for Claude
6. **Fix Format Requirements** — strict JSON schema; before/after must match code exactly
7. **Formatting Rules** — JSON-only output; no hallucinated code
8. **Example Fixes** — correct and incorrect examples to calibrate Claude's output

### Accuracy by Failure Type (Reported)

| Failure Category | Accuracy |
|-----------------|----------|
| Wrong `data-cy` selectors | 90% |
| Wrong assertion text (typos) | 70% |
| Wrong custom command usage | 50% |
| Wrong input data / URL | 50% |
| Missing checkbox interaction | 20% |
| Element no longer exists | 40% |
| Truly unfixable (503, infra) | 100% correctly identified as unfixable |

### Common Failure Modes

- **Code hallucinations** — Claude suggests fixes for code snippets that don't exist
- **Wrong file/function mapping** — fix linked to the wrong location
- **Hardcoded values** — replaces existing variables with hardcoded strings
- **Missed root cause** — stops at first failure instead of finding all issues

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| Dramatically reduces manual maintenance for selector rot | 50–70% accuracy on complex failures — not production-ready alone |
| Full human review via MR — safe workflow | Requires HTML snapshot infrastructure |
| 90% accuracy on the most common failure type (wrong selectors) | Needs tight prompt engineering; context quality is critical |
| Open source; adaptable to any CI system | Claude struggles without sufficient app context (routes, globals) |

---

## Approach 5: Claude Code Subagents for Parallel Test Suite Generation

**Sources:** [Dev.to: Claude Code Subagents](https://dev.to/subprime2010/claude-code-subagents-how-to-run-parallel-tasks-without-hitting-rate-limits-4bpl), [Anthropic Sub-agents Docs](https://docs.anthropic.com/en/docs/claude-code/sub-agents)

### What It Is

Claude Code supports spawning multiple **subagents** — independent AI instances that each work on isolated tasks in parallel with separate context windows and token budgets. Applied to Cypress suites, you can generate, review, or analyze multiple test directories simultaneously without hitting the sequential bottleneck of a single Claude session.

### Architecture for Parallel Spec Generation

```
Main Claude Agent
       │
       ├─► Subagent 1: Generate specs for cypress/e2e/auth/**
       ├─► Subagent 2: Generate specs for cypress/e2e/billing/**
       ├─► Subagent 3: Generate specs for cypress/e2e/dashboard/**
       └─► Subagent 4: Generate specs for cypress/e2e/settings/**
             │
             └─► Each reports: pass/fail counts + error messages
```

A project with 12 sequential test files taking ~8 minutes can be reduced to under 3 minutes using 4 parallel subagents.

### Programmatic Setup (Claude Agent SDK)

```typescript
import { ClaudeSDKClient } from '@anthropic-ai/claude-code-sdk';

const client = new ClaudeSDKClient();

const testDirs = ['auth', 'billing', 'dashboard', 'settings'];
const results = await Promise.all(
  testDirs.map(dir =>
    client.query({
      prompt: `Generate comprehensive Cypress specs for cypress/e2e/${dir}/.
               Follow CLAUDE.md conventions. Output spec files only.`,
      agents: ['generalPurpose'],
      allowedTools: ['Read', 'Write', 'Bash'],
      systemPrompt: 'You are a Cypress E2E test author. Use data-cy selectors only.'
    })
  )
);
```

### CLI Subagent with Custom System Prompt

```bash
claude --agent-type explore \
  --print \
  "Read all component files in src/components/Auth/ and generate 
   Cypress specs in cypress/e2e/auth/. Follow CLAUDE.md conventions."
```

### Rate Limit Strategy

Each subagent uses a **separate token budget** with staggered start times to avoid simultaneous rate limit pressure:

```typescript
const stagger = (index: number) => 
  new Promise(resolve => setTimeout(resolve, index * 2000));

await Promise.all(
  testDirs.map(async (dir, i) => {
    await stagger(i);
    return generateSpecsForDir(dir);
  })
);
```

### Key Risk: Scope Creep

The biggest challenge: a subagent assigned to `auth/` may modify shared `commands.ts` or page objects, conflicting with another subagent doing the same. Mitigate with:
- Clear boundary definitions in each subagent's system prompt
- Explicit file access lists in `allowedTools`
- A final merge-and-review step by the main agent

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| Dramatically reduces wall-clock time for large suites | Scope creep risk when subagents share support files |
| Separate context windows avoid token accumulation | More complex orchestration logic |
| Staggered execution helps avoid rate limits | Harder to debug when one subagent silently produces bad output |
| Built into Claude Code — no external infra | Still requires CLAUDE.md / AGENTS.md conventions to be effective |

---

## Approach 6: Decipher x Claude Code — Agentic Self-Maintaining Tests (Commercial)

**Sources:** [Decipher Blog](https://getdecipher.com/blog/decipher-x-claude-let-claude-code-generate-self-maintaining-e2e-tests)

### What It Is

Decipher is an agentic QA platform that integrates directly with Claude Code via an MCP-style interface. Claude describes what to test, Decipher's agents execute it in a real managed browser with vision + DOM validation, and tests are stored and maintained on Decipher's infrastructure.

### How It Works

1. Install Decipher's Claude Code plugin
2. Describe a flow to Claude: `"Test workflow generation: go through setup, select GPT5, save. Assert the generation completes."`
3. Claude sends steps → Decipher's agent executes in a real browser
4. If a step fails, Decipher sends Claude a screenshot + feedback → Claude adjusts → retries
5. Result: a validated, browser-confirmed test stored on Decipher
6. As your product changes, Decipher automatically updates the tests

### Supported Interactions via Claude Chat

```
# Describe a flow
"Test workflow generation: go through setup, select GPT5, save."

# Bulk creation
"Make 10 tests for each filter on /dashboard. Test edge cases for each."

# Update tests
"Our account creation test is failing because we removed oauth. 
 Update it to use email and password."

# Coverage analysis
"Which pages or flows are we not covering with our tests today?"
```

### Why It Differs from Static Playwright/Cypress Generation

| Problem with Static Generation | Decipher's Solution |
|---------------------------------|---------------------|
| Guesses selectors from code context | Validates in real browser via vision + DOM |
| You own the infra (runners, retries) | Managed browser infrastructure |
| Static: rename a button → CI fails | Continuous auto-update as product changes |
| Stack trace + screenshot only | Plain-language failure explanations (real bug vs. flow change) |
| No visual assertions | Visual + semantic evaluation, not just DOM |

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| True agentic loop: Claude writes, Decipher validates | Commercial — paid platform |
| Self-maintaining: no manual locator updates | Lock-in to Decipher's infrastructure |
| Visual assertions without pain | Less control vs. self-hosted |
| Plain-language failure reasoning | Early-stage product; feature surface still evolving |

---

## Approach 7: `cy.ai` — Local LLM via Ollama (Open Source, No Cloud)

**Sources:** [remarkablemark Medium post](https://remarkablemark.medium.com/cypress-ai-command-30eadacc8e68), [GitHub: remarkablemark](https://github.com/remarkablemark/remarkablemark.github.io/blob/master/_posts/2025/2025-06-01-cypress-ai-command.md)

### What It Is

`cy.ai` is an open-source community Cypress plugin (reviewed June 2025) that runs a local LLM via Ollama to generate and execute Cypress commands from natural language—without any external API key, cloud account, or paid service. This is the privacy-first / air-gapped approach.

### How It Works

1. Claude/LLM is replaced by a local model (`qwen2.5-coder` recommended)
2. A prompt is constructed from your task description + current HTML body
3. The prompt is sent to the local Ollama server (HTTP)
4. The LLM returns Cypress code, which is cleaned and executed
5. Generated code is cached to `cypress/e2e/**/__generated__/*.json` for reuse

### Setup

```bash
# Install Ollama and pull model
brew install ollama
ollama pull qwen2.5-coder

# Install the plugin
npm install cy-ai --save-dev
```

```javascript
// cypress/support/commands.js
import 'cy-ai'
```

```javascript
// cypress/e2e/login.cy.js
describe('Login', () => {
  it('logs in with valid credentials', () => {
    cy.visit('/login')
    cy.ai('Fill in email with user@example.com and password with secret, then submit')
  })
})
```

```javascript
// cypress.config.js
module.exports = {
  chromeWebSecurity: false, // required to avoid CORS with Ollama
}
```

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| No API key, no cloud account | Local model quality much lower than Claude Sonnet |
| Works offline / air-gapped environments | Slower inference on consumer hardware |
| Zero ongoing cost | No self-healing, no caching across projects |
| No data sent to external services | Limited community support vs. official tools |

---

## Approach 8: Community MCP Servers for Cypress (GitHub)

**Sources:** [miroslavmyrha/cypress-mcp](https://github.com/miroslavmyrha/cypress-mcp), [yashpreetbathla/cypress-mcp](https://github.com/yashpreetbathla/cypress-mcp)

### What It Is

Community-built MCP servers that expose Cypress testing capabilities to Claude (and other MCP-compatible AI clients) — similar in concept to the official Cypress Cloud MCP, but focused on **local test execution and spec file access** rather than Cypress Cloud data.

### Available Tools in Community MCP Servers

| Tool | What It Does |
|------|-------------|
| `list_specs` | Lists all Cypress spec files in the project |
| `read_spec` | Returns the content of a specific spec file |
| `get_test_results` | Retrieves results from the most recent test run |
| `run_spec` | Executes a specific spec file and returns results |
| `get_dom_snapshot` | Returns the DOM snapshot from the last test run |
| `get_command_log` | Returns the Cypress command log |
| `get_error_messages` | Returns error messages from failed tests |

### Use Cases

- Claude reads spec files and identifies coverage gaps
- Claude runs a spec, gets DOM snapshot + command log + errors, diagnoses failures inline
- Claude proposes locator changes and immediately re-runs to verify the fix

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| Works without Cypress Cloud | Community-maintained; stability not guaranteed |
| Gives Claude access to local run data | Smaller feature set than official Cloud MCP |
| Enables agentic fix-and-verify loops locally | Requires local MCP server setup |

---

## Summary Comparison Table

| # | Approach | Who Makes It | Claude Needed? | Cypress Cloud Needed? | Best For |
|---|----------|-------------|----------------|----------------------|----------|
| 1 | **AGENTS.md / CLAUDE.md** | Community pattern | Yes | No | Encoding conventions for Claude Code |
| 2 | **GitHub Actions + Claude Code** | Anthropic + community | Yes (Claude Code) | No | Auto-generating specs on every PR |
| 3 | **Multi-LLM Framework** | Open source | Yes (one option) | No | Model-agnostic spec generation from CLI |
| 4 | **Self-Healing LLM Prototype** | Open source | Yes (Sonnet 3.5) | No | Automated fix proposals for failing tests |
| 5 | **Claude Code Subagents** | Anthropic | Yes (Claude Code) | No | Parallelizing large-scale spec generation |
| 6 | **Decipher x Claude** | Commercial (Decipher) | Yes (Claude Code) | No | Self-maintaining tests with browser validation |
| 7 | **`cy.ai` (Ollama)** | Open source | No (local LLM) | No | Air-gapped / privacy-first environments |
| 8 | **Community MCP Servers** | Community | Yes | No | Local test run access for AI agents |

---

## Recommended Integration Path for an Existing Cypress Suite (like Kiali)

For a mature Gherkin-based regression suite with existing specs, the most practical combination is:

### Phase 1: Context Engineering (Zero Cost, High Value)
Add `AGENTS.md` and `CLAUDE.md` files to encode testing conventions so Claude generates output that fits immediately:
- Gherkin feature file location and naming conventions
- Step definition locations and how custom steps are organized
- Selector strategy and Page Object locations
- Which commands to avoid in CI/agentic contexts (no `cypress:open`, no full-suite runs)

Example `CLAUDE.md` snippet for a Gherkin suite:
```markdown
## Test Conventions
- Tests are written in Gherkin (`.feature` files) in `cypress/e2e/features/`
- Step definitions live in `cypress/e2e/step_definitions/`
- Use `cypress-cucumber-preprocessor` as the runner
- Selectors use `data-cy` attributes exclusively
- Page Objects live in `cypress/support/pages/`
- Run a single feature: `cypress run --spec "cypress/e2e/features/auth.feature"`
- Never run the full suite; always target a specific feature file or tag
- Use `@tag` annotations to group scenarios by domain
```

### Phase 2: Claude Code + Community MCP Server for Local Failure Triage
Use a community MCP server (`cypress-mcp`) to give Claude direct access to local test run data — spec content, command logs, DOM snapshots, and error messages — without needing Cypress Cloud. Claude can then diagnose failures and propose fixes in a tight loop.

### Phase 3: LLM-Powered Self-Healing for Selector Rot
Wire Claude Sonnet into the CI failure pipeline (Approach 5) to automatically propose patches for broken selectors and open draft PRs for human review. This directly targets the most common maintenance pain point in Gherkin step definitions.

### Phase 4: GitHub Actions Auto-Generation for New Features (Optional)
Add the Claude Code GitHub Action to PRs to automatically generate new Gherkin scenarios and step definitions for changed frontend components, following the conventions encoded in Phase 1.

---

## References

- [Self-Healing in Cypress Blog](https://www.cypress.io/blog/ai-self-healing-in-cypress-reliable-tests-with-full-visibility/)
- [Cypress AGENTS.md PR #33429](https://github.com/cypress-io/cypress/pull/33429)
- [ITNEXT: Self-Healing E2E with LLMs](https://itnext.io/self-healing-e2e-tests-reducing-manual-maintenance-efforts-using-llms-db35104a7627)
- [Multi-LLM Test Generation (GoPenAI)](https://blog.gopenai.com/multi-llm-test-automation-generate-cypress-and-playwright-tests-with-chatgpt-claude-or-gemini-04aedc297da1)
- [GitHub: ai-natural-language-tests](https://github.com/aiqualitylab/ai-natural-language-tests)
- [GitHub: self-healing-e2e-tests-prototype](https://github.com/agune15/self-healing-e2e-tests-prototype)
- [Decipher x Claude Blog](https://getdecipher.com/blog/decipher-x-claude-let-claude-code-generate-self-maintaining-e2e-tests)
- [Claude Code Sub-agents Docs](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Claude Code GitHub Actions](https://docs.anthropic.com/en/docs/claude-code/github-actions)
- [SmartScope: Claude Code + GitHub Actions](https://smartscope.blog/en/ai-development/github-actions-automated-testing-claude-code-2025/)
- [GitHub: anthropics/claude-code-action](https://github.com/anthropics/claude-code-action)
- [GitHub: miroslavmyrha/cypress-mcp](https://github.com/miroslavmyrha/cypress-mcp)
- [GitHub: yashpreetbathla/cypress-mcp](https://github.com/yashpreetbathla/cypress-mcp)
- [GitHub: tjmaher/claude-cypress-login](https://github.com/tjmaher/claude-cypress-login)
- [remarkablemark: cy.ai command](https://remarkablemark.medium.com/cypress-ai-command-30eadacc8e68)
- [Claude Code Subagents (Dev.to)](https://dev.to/subprime2010/claude-code-subagents-how-to-run-parallel-tasks-without-hitting-rate-limits-4bpl)
