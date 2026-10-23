# AGENTS.md Refactoring Plan

Research-grounded guide for shrinking and restructuring this repo's agent-instruction files.
Branch: `agents-md-refactoring`. Status: research complete, implementation not started.

Sources: web research (24 primary sources, Nov 2026 — see "External evidence" below),
local recon (inventory, duplication map, git-churn analysis, consumer verification).

---

## 1. Current state (measured)

- `AGENTS.md`: **2101 lines, 8,536 words, 70,100 bytes (~11–13k tokens)**.
  - **70.1 KiB exceeds OpenAI Codex's default 32 KiB `project_doc_max_bytes` cap → Codex users get a truncated file today.**
- Verified consumers (must keep working after refactor):
  - **pi** — root `AGENTS.md` injected as `project_instructions` (verified live).
  - **Claude Code** — no `CLAUDE.md` exists, so Claude Code reads `AGENTS.md` by default; `.claude/rules/*.md` + `.claude/skills/` loaded separately.
  - **Cursor** — `.agents/rules/` with dual frontmatter (`alwaysApply`/`globs` for Cursor, `paths` for Claude Code).
  - **GitHub Actions OpenWiki** — `.github/workflows/openwiki-update.yml:57-61` stages `AGENTS.md` daily; the ONLY CI reference to it.
- `.claude/` and `.agents/` are **copied twin trees, not symlinks** (rules verified identical via diff). New skills must go to both.
- Skills pattern proven: 9 existing `.agents/skills/*/SKILL.md` (name + description frontmatter).
- Architecture layer already exists: `docs/agents/` (8 docs, 2,943 lines) + `openwiki/architecture/` (5 pages, 1,258 lines).

### Section inventory and disposition

| Section (lines) | ~% | Disposition |
|---|---|---|
| Title + TOC (1–23) | 1 | regenerate |
| Supported Branches (25–39) | 1 | **keep** (small, high value; known drift engine — update per release) |
| Quick Reference (41–91) | 2 | keep core (build order, repo structure, symlink setup) |
| Code Quality Standards (93–234) | 7 | **condense to invariants + pointer** → `STYLE_GUIDE.adoc`, `.agents/rules/code-quality.md`, `go.md`, `comments.md` |
| Building and Testing (236–862) | **30** | keep build/test/local-run essentials; suites table → compact (or pointer to `hack/run-integration-tests.sh --help`); **Cypress-MCP debugging (365–798) → skill**; **writing e2e tests (799–845) → skill**; **CI-failure repro (598–680) → skill** |
| Development Workflows hot-reload (864–890) | 1 | keep |
| Cluster-Specific Workflows (892–1308) | **20** | **condense hard** → env-var table + pointers to `hack/k8s-minikube.sh --help`, `hack/start-kind.sh --help`, `hack/crc-openshift.sh --help` |
| Operator Development (1310–1537) | 11 | condense; **molecule tests → skill**; checklists → pointer |
| File Protection Rules (1539–1568) | 1 | **keep condensed inline** (critical; Codex never follows links) |
| Common Patterns checklists (1570–1722) | 7 | condense to pointer (references external kiali-operator repo anyway) |
| Troubleshooting (1724–1819) | 5 | trim to high-frequency items |
| Additional Resources (1821–1841) | 1 | fold into pointer index |
| Quick Command Reference (1843–1994) | **7** | **DELETE — internal duplicate** of Cluster-Specific + Testing + Operator |
| Creating Pull Requests (1996–2048) | 3 | keep condensed + pointer to `CONTRIBUTING.md` |
| Important Reminders (2050–2084) | 2 | **DELETE recap** — fold critical bits (build order, env vars) into top |
| Architecture docs table (2086–2101) | 1 | keep one-line pointer to `docs/agents/` |

### Confirmed duplication / staleness

- Quick Command Reference ≈ internal repeat of earlier sections.
- Code Quality Standards duplicates `STYLE_GUIDE.adoc` + `.agents/rules/*`.
- File Protection Rules duplicated in `.agents/rules/file-protection.md` (keep rule file; AGENTS.md keeps condensed).
- Cluster workflows duplicate `hack/*.sh --help` output.
- CI-suite table already drifted (workflows have `chat`/`core-caching` suites missing from table).
- Stale links: `RELEASING.adoc` (actual file `RELEASING.md`), `operator/DEVELOPING.adoc` (operator/ is an external-repo symlink, absent in many checkouts).
- Git churn: branch/version table + suite table are the top drift engines (commits #9984, #9955, #9829…).

---

## 2. External evidence (key findings, sources in research notes)

- **Size guidance**: Claude Code official "<200 lines per file"; Cursor "<500 lines"; HumanLayer instruction budget ~150–200, consensus <300 lines; Codex hard 32 KiB chain cap.
- **Bloat degrades agents** (adjacent evidence, inference): IFScale — best frontier model 68% instruction-following at 500 instructions; context rot (Chroma); lost-in-the-middle positional decay.
- **Precedents** (verified line counts): grafana 180 (root index + nested dir AGENTS.md + skills — **best kiali analog**), cloudflare/workers-sdk 157 ("prefer authoritative config over copied details"), nodejs/node 64, rust 258, next.js 546 (counter-example). Kiali = 2101 → 4–13× over.
- **Progressive disclosure mechanics**:
  - Plain links are NOT auto-fetched by most tools. Cursor reads referenced files on demand; Claude Code `@` imports load eagerly (organize ≠ save context); Gemini CLI JIT-loads per-directory context files; **Codex follows no links at all — only its AGENTS.md chain**.
  - Pattern that works: self-descriptive filenames + one-line descriptions in the index + explicit "read X before doing Y" instruction.
- **Nested AGENTS.md**: spec = "nearest file wins"; auto-applied by Cursor, Claude Code (on-demand when editing files there), Copilot, Gemini-JIT. Codex loads root→cwd at session start only.
- **Anti-patterns kiali currently hits**: style rules in prose (linters exist), duplicating README/CONTRIBUTING/script-help, file-path inventories, per-mistake rule accumulation, copied volatile counts.
- **Trend (2025–26)**: small root + nested per-component files + skills for procedures + linters/CI for verifiable rules. Counter-rule: critical universal rules stay inline (agents skip optional-sounding links).

---

## 3. Target structure

```
AGENTS.md                      ~250–350 lines, <16 KiB (well under Codex cap)
  - identity, build order, repo layout (capability level, not paths)
  - code-standard invariants (terse) + pointers
  - file protection (condensed, inline)
  - PR/fork workflow (condensed) + CONTRIBUTING.md pointer
  - supported branches table (small, volatile — accepted)
  - compact test-suite tag table
  - pointer index: docs/agents/*, hack/* --help, STYLE_GUIDE.adoc
  - skills index table with trigger phrases

frontend/AGENTS.md             ~60–100 lines (optional, phase 2)
  - frontend build/test, Playwright migration conventions, i18n, styling tokens

.agents/skills/<new>/SKILL.md  (×4, phase 1)
  - cypress-mcp-debugging   (~430 lines from AGENTS.md 365–798)
  - ci-failure-repro        (~85 lines from 598–680)
  - write-e2e-tests         (~50 lines from 799–845)
  - molecule-testing        (~90 lines from operator section)

.agents/rules/*                unchanged (already compact duplicates)
.claude/*                      mirror of .agents/* (keep trees in sync)
docs/agents/*, openwiki/*      unchanged (architecture layer)
```

Rejected: nested `operator/AGENTS.md` (operator/ is a symlink to the separate kiali-operator
repo — cross-repo commit, absent in CI checkouts). Deferred: consolidating/moving existing
human docs (external inbound links from kiali.io; worst risk/benefit).

---

## 4. Implementation phases

**Phase 0 — baseline**
- Record `wc -l -w -c AGENTS.md` (2101 / 8536 / 70100).
- Decide `.claude/` ↔ `.agents/` sync strategy (copy both, or convert to symlinks per `.agents/README.md`).

**Phase 1 — extract skills** (biggest single win, ~650–900 lines)
- Create 4 SKILL.md files above; frontmatter `name` + `description` written to match natural
  trigger queries ("debugging a failing Cypress test", "reproduce CI failure locally", …).
- Copy to both `.agents/skills/` and `.claude/skills/`.

**Phase 2 — nested frontend/AGENTS.md** (optional)
- Move frontend-specific conventions out of root. Verify no tool regression (Cursor/Claude Code
  auto-load; pi unverified — keep anything pi-critical in root).

**Phase 3 — rewrite root AGENTS.md lean**
- Apply disposition table. Delete Quick Command Reference + Important Reminders entirely.
- Fix stale links (RELEASING.md, operator caveat).
- Keep critical rules inline (file protection, build order) — Codex never follows links.

**Phase 4 — OpenWiki regeneration**
- Trigger `workflow_dispatch` on openwiki-update.yml once; review the generated PR diff.

**Phase 5 — validation**
1. Token/size: target <2,500 words, <16 KiB.
2. pi dry-run: fresh subagent session — confirm lean AGENTS.md injects and answers
   build order + protected files correctly.
3. Claude Code dry-run: `claude -p "what files must I never modify"` — protected-files
   answer must still resolve (from AGENTS.md inline or `.claude/rules/file-protection.md`).
4. Link check: script extracting every relative path in new AGENTS.md → `test -e` each.
5. Stale-heading grep: grep repo for removed section anchor names.
6. Skills: invoke each new skill by name once.

---

## 5. Risks

| Risk | Mitigation |
|---|---|
| Skill content invisible unless invoked (pull, not push) | Skills index table in AGENTS.md with trigger phrases; descriptions written for query match |
| `.claude/`/`.agents/` copy drift | Add to both in same PR; consider sync-check script or symlinks |
| Codex ignores links entirely | Critical rules (file protection, build order) stay inline in AGENTS.md chain |
| Claude Code relevance-gating skips prose pointers | "read X before doing Y" phrasing; self-descriptive doc names |
| OpenWiki one-time large regen diff / dead pointers | Full link-check pre-merge; workflow_dispatch review before merge |
| Branch/suite tables keep drifting | Accepted (small); update per release; consider generating from workflows |

---

## 6. Gaps / assumptions

- pi's nested-AGENTS.md loading behavior: unverified — assume root-only (verified root works).
- Amp/Jules/Factory loading docs: unverifiable (login-gated/404) — not consumers here anyway.
- Inbound deep links from kiali.io or other repos into AGENTS.md sections: not audited.
- No AGENTS.md-length-specific benchmark exists (IFScale/context-rot are adjacent evidence).
- `openwiki` exact parsing of AGENTS.md beyond `add-paths` (workflow lines 57–61): unverified.
