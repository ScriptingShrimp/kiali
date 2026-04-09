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

## Generation Rules
- Generate positive, negative, and boundary value tests for each changed flow
- Use data-cy selectors exclusively; never use CSS class selectors
- Target 80%+ coverage of user-visible interactions
- Use cy.intercept() for network stubbing; never use cy.wait(number)
- Follow Page Object Model: page objects in cypress/support/pages/
- Placeholders for secrets: use Cypress.env()
- No bare cy.wait() — alias intercepts and use cy.wait('@alias')
```

### Tradeoffs

| ✅ Pros | ⚠️ Cons |
|---------|---------|
| No runtime cost — pure documentation | Requires human maintenance as repo evolves |
| Works with any AI agent (Claude, Codex, Cursor) | Quality of AI output still depends on quality of context files |
| Prevents AI from running destructive commands | Does not generate tests; only guides generation |
| Encodes team conventions permanently | Needs to be added to every package that needs AI guidance |

---

## Approach 2: Multi-LLM Test Generation Framework (Open Source)

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

### Enforcing Generation Rules via Prompt

The framework accepts a custom system prompt. Pass the shared generation rules to keep Claude's output consistent with the rest of the suite:

```bash
python qa_automation.py \
  "Test login with valid credentials" \
  --url https://myapp.com/login \
  --llm anthropic \
  --system-prompt "Generation Rules:
- Generate positive, negative, and boundary value tests for each flow
- Use data-cy selectors exclusively; never use CSS class selectors
- Target 80%+ coverage of user-visible interactions
- Use cy.intercept() for network stubbing; never use cy.wait(number)
- Follow Page Object Model: page objects in cypress/support/pages/
- Placeholders for secrets: use Cypress.env()
- No bare cy.wait() — alias intercepts and use cy.wait('@alias')"
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

## Approach 3: Claude Code Subagents for Parallel Test Suite Generation

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
      systemPrompt: `You are a Cypress E2E test author. Follow these rules:
- Generate positive, negative, and boundary value tests for each flow
- Use data-cy selectors exclusively; never use CSS class selectors
- Target 80%+ coverage of user-visible interactions
- Use cy.intercept() for network stubbing; never use cy.wait(number)
- Follow Page Object Model: page objects in cypress/support/pages/
- Placeholders for secrets: use Cypress.env()
- No bare cy.wait() — alias intercepts and use cy.wait('@alias')`
    })
  )
);
```

### CLI Subagent with Custom System Prompt

```bash
claude --agent-type explore \
  --print \
  "Read all component files in src/components/Auth/ and generate
   Cypress specs in cypress/e2e/auth/. Follow CLAUDE.md conventions.
   Generation rules:
   - Generate positive, negative, and boundary value tests for each flow
   - Use data-cy selectors exclusively; never use CSS class selectors
   - Target 80%+ coverage of user-visible interactions
   - Use cy.intercept() for network stubbing; never use cy.wait(number)
   - Follow Page Object Model: page objects in cypress/support/pages/
   - Placeholders for secrets: use Cypress.env()
   - No bare cy.wait() — alias intercepts and use cy.wait('@alias')"
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

## Summary Comparison Table

| # | Approach | Who Makes It | Claude Needed? | Cypress Cloud Needed? | Best For |
|---|----------|-------------|----------------|----------------------|----------|
| 1 | **AGENTS.md / CLAUDE.md** | Community pattern | Yes | No | Encoding conventions for Claude Code |
| 2 | **Multi-LLM Framework** | Open source | Yes (one option) | No | Model-agnostic spec generation from CLI |
| 3 | **Claude Code Subagents** | Anthropic | Yes (Claude Code) | No | Parallelizing large-scale spec generation |

---

## Recommended Integration Path for an Existing Cypress Suite (like Kiali)

For a mature Gherkin-based regression suite with existing specs, the most practical combination is:

### Phase 1: Context Engineering (Zero Cost, High Value)

Add `AGENTS.md` files at the right granularity so any AI agent loads focused, accurate context for the area it is working in. The key insight for Kiali is that the repo already has a root `AGENTS.md` with Go backend conventions — frontend Cypress conventions should not be buried there. A dedicated hierarchy keeps each file small and purposeful.

**Recommended file structure for Kiali:**

```
kiali/
├── AGENTS.md                    ← Go backend conventions (already exists)
│
└── frontend/
    ├── AGENTS.md                ← Frontend overview: toolchain, yarn commands, where things live
    └── cypress/
        ├── AGENTS.md            ← Gherkin-specific rules (the highest-value file)
        └── perf/
            └── AGENTS.md        ← "raw spec.ts, no Gherkin" disambiguation (optional)
```

The `perf/` subfolder uses plain `.spec.ts` files and a different runner pattern than the Gherkin integration suite. A short `AGENTS.md` there prevents an agent from trying to apply Cucumber conventions to performance specs.

**What `frontend/cypress/AGENTS.md` should encode:**

This is the file an agent loads when you ask it to look at a failing feature file or write a new scenario. It should cover:

- How to map a `.feature` file to its step definition: `featureFiles/graph.feature` → `common/graph.ts` (same base name, different directory)
- Feature files live in `cypress/integration/featureFiles/`, step definitions in `cypress/integration/common/`
- Runner: `cypress-cucumber-preprocessor`; run a single feature with `cypress run --spec "cypress/integration/featureFiles/graph.feature"`
- Never run the full suite; always target a specific feature file or tag
- Selectors use `data-cy` attributes exclusively — never CSS class selectors
- `cy.wait(number)` is banned; use `cy.intercept()` with named aliases and `cy.wait('@alias')` instead
- Custom commands are in `cypress/support/commands.ts`; shared hooks in `cypress/integration/common/hooks.ts`
- `perf/` specs are a separate concern — do not modify them when working in `integration/`
- Use `@tag` annotations to group scenarios by domain

Example `cypress/AGENTS.md` content for Kiali:
```markdown
## Cypress Test Conventions

### Structure
- Gherkin feature files: `cypress/integration/featureFiles/<name>.feature`
- Step definitions:       `cypress/integration/common/<name>.ts` (same base name as feature file)
- Shared custom commands: `cypress/support/commands.ts`
- Shared hooks:           `cypress/integration/common/hooks.ts`
- Performance specs:      `cypress/perf/*.spec.ts` — plain Cypress, no Gherkin, separate concern

### Running Tests
- Single feature: `cypress run --spec "cypress/integration/featureFiles/graph.feature"`
- Never run the full suite; always target a specific feature file or tag
- Never use `cypress open` in agentic/CI contexts

### Selectors
- Use `data-cy` attributes exclusively; never use CSS class selectors

### Async / Network
- `cy.wait(number)` is banned
- Use `cy.intercept()` with named aliases: `cy.wait('@alias')`

### Conventions
- Use `@tag` annotations to group scenarios by domain
- Runner: `cypress-cucumber-preprocessor`
```

**What context engineering alone covers — and what it does not:**

AGENTS.md files tell the agent *how the suite is structured*. They enable correct test authoring and prevent the agent from running destructive commands. They do not give the agent access to runtime failure data — paste failure output directly into context for ad-hoc triage.

| Goal | What delivers it |
|------|-----------------|
| Agent writes correct new Gherkin scenarios and step definitions | `cypress/AGENTS.md` with conventions |
| Agent understands why a specific test failed | Pasting failure output directly into context |
| Agent fixes a broken `data-cy` selector | `cypress/AGENTS.md` conventions |
| Agent identifies missing scenario coverage | `cypress/AGENTS.md` + asking it to read the feature files |

### Phase 2: LLM-Powered Self-Healing for Selector Rot

Wire Claude Sonnet into the CI failure pipeline to automatically propose patches for broken selectors and open draft PRs for human review. This directly targets the most common maintenance pain point in Gherkin step definitions: selectors drifting as the UI evolves.

### Phase 3: Claude Code Subagents for Bulk Generation (Optional)

Use Claude Code subagents (Approach 3) to generate Gherkin scenarios and step definitions for multiple feature domains in parallel — each subagent scoped to one feature file and its matching step definition file, following the conventions encoded in Phase 1. The 1:1 naming convention (`featureFiles/X.feature` ↔ `common/X.ts`) makes scope boundaries natural and reduces the risk of subagents conflicting over shared files.

---

### Complete Generation Workflow: Synthesizing All Approaches

When the phases above are in place, use this structured workflow to generate new Gherkin scenarios and step definitions for any feature — without an external framework, but applying the same structured reasoning that makes Approach 2 effective.

**The pipeline, adapted for direct use with Claude:**

```
Step 1: Read component source      (Claude reads the React component / page source)
      ↓
Step 2: Analyze stable selectors   (Claude identifies data-cy, aria-*, and text anchors in the source)
      ↓
Step 3: Check existing patterns    (Claude reads a similar existing .feature + step definition pair)
      ↓
Step 4: Generate the spec          (Claude writes the .feature + matching step definition)
```

All steps require only Phase 1 (AGENTS.md context) and can run without a live cluster.

**Self-contained generation prompt**

Use this prompt directly in Claude Code or Cursor. It encodes the conventions inline so it works even before AGENTS.md files exist in the repo.

```
You are writing Cypress/Gherkin tests for the Kiali observability UI.

## Your task
1. Read the component source at [path/to/component].
2. Identify all `data-cy` attributes, `aria-label` values, and stable text anchors
   in that source. Do not select by CSS class.
3. Read the most similar existing feature file (e.g. cypress/integration/featureFiles/graph.feature)
   and its step definitions (cypress/integration/common/graph.ts) to understand the established
   pattern before writing anything.
4. Generate:
   - A new `.feature` file at `cypress/integration/featureFiles/<name>.feature`
   - A matching step definition at `cypress/integration/common/<name>.ts`
   following the same base-name convention as the existing pairs.

## Generation rules (apply to all output)
- Use `data-cy` attributes exclusively for element selection; never use CSS class selectors
- Generate positive tests, negative tests, and boundary / edge cases for each flow
- Use `cy.intercept()` with named aliases; never use `cy.wait(number)` or bare `cy.wait()`
- Reference `Cypress.env()` for secrets or environment-specific values; never hardcode them
- Organise scenarios with `@tag` annotations (e.g. `@auth`, `@graph`, `@table`)
- Runner: `cypress-cucumber-preprocessor`
  Single-feature run: `cypress run --spec "cypress/integration/featureFiles/<name>.feature"`
- Do not read or modify anything under `cypress/perf/` — it uses a different runner
  and is a separate concern

## What to expect from Claude's output
Claude adds assertions that are not explicitly requested: for example, asserting that an
error message disappears after a successful action, or asserting intermediate loading states.
Keep these in review — they reflect a complete view of the user flow, not noise.
```

**Pattern consistency — lightweight alternative to a vector store**

Approach 2's vector store (step 3 in the pipeline) keeps generated output consistent across multiple generation runs by surfacing past specs as reference material. You can achieve the same effect without infrastructure by maintaining a small set of canonical reference specs:

```
cypress/integration/featureFiles/
└── _examples/
    ├── auth.feature       ← canonical example: authentication flow
    ├── graph.feature      ← canonical example: graph interaction
    └── table.feature      ← canonical example: sortable / filterable table
```

Add one line to `cypress/AGENTS.md`:

```markdown
### Reference Examples
Before generating a new spec, read the closest example in `cypress/integration/featureFiles/_examples/`
and match its structure, tag style, and step definition patterns.
```

This costs nothing at runtime and keeps generated specs structurally consistent without an external vector store or Python dependency.

**What each phase and approach contributes to this workflow**

| Step | What delivers it |
|------|-----------------|
| Read component source | Claude Code (built-in file access) |
| Identify stable selectors | Claude's analysis pass — guided by `cypress/AGENTS.md` selector rules (Phase 1) |
| Check existing patterns | Reference examples in `_examples/` — lightweight pattern history (Phase 1) |
| Generate spec + step definition | Claude — guided by the self-contained prompt above |
| Fix selector rot automatically | Phase 2: Self-healing pipeline |
| Generate at scale across domains | Phase 3: Claude Code subagents, one per feature file |

---

## References

- [Cypress AGENTS.md PR #33429](https://github.com/cypress-io/cypress/pull/33429)
- [Multi-LLM Test Generation (GoPenAI)](https://blog.gopenai.com/multi-llm-test-automation-generate-cypress-and-playwright-tests-with-chatgpt-claude-or-gemini-04aedc297da1)
- [GitHub: ai-natural-language-tests](https://github.com/aiqualitylab/ai-natural-language-tests)
- [Claude Code Sub-agents Docs](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [GitHub: tjmaher/claude-cypress-login](https://github.com/tjmaher/claude-cypress-login)
- [Claude Code Subagents (Dev.to)](https://dev.to/subprime2010/claude-code-subagents-how-to-run-parallel-tasks-without-hitting-rate-limits-4bpl)
