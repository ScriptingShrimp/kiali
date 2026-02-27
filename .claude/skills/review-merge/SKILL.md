---
name: review-merge
description: Review the most recently merged PR on master. Finds the latest merge, gathers PR metadata, and performs a file-by-file code review with Kiali-specific standards.
disable-model-invocation: true
argument-hint: "[pr-number]"
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *)
---

# Review Merged PR

Review a pull request that was merged into master. If a PR number is provided as `$ARGUMENTS`, review that PR. Otherwise, find the most recently merged PR.

## Latest merged PR (for reference)

!`gh pr list --state merged --base master --limit 1 --json number,title,author,mergedAt`

## Step 1: Identify the target PR

- If `$ARGUMENTS` is provided, use that as the PR number.
- Otherwise, parse the PR number from the JSON above.

## Step 2: Gather PR metadata

Run the following to understand what the PR is about:

```
gh pr view <number> --json title,body,files,commits,comments,reviews,labels,mergedAt,author
```

Note the PR description, any unaddressed review comments, and the commit messages.

## Step 3: Get the list of changed files

```
gh pr diff <number> --name-only
```

Do NOT load the full diff into context. Work file-by-file using the Read tool.

## Step 4: File-by-file review

For each changed file:

1. Use the Read tool to examine the file.
2. Use `gh pr diff <number> -- <filepath>` only for individual files when you need to see what specifically changed (additions/deletions).
3. Check surrounding context with Grep/Glob when needed.

Focus on finding **actual bugs, security issues, and correctness problems** rather than style nitpicks.

## Step 5: Delegate specialized analysis

Use the pr-review-toolkit agents for deeper analysis. Invoke them as needed:

- `/pr-review-toolkit:review-pr tests` -- for test coverage gaps
- `/pr-review-toolkit:review-pr errors` -- for silent failure / error handling issues
- `/pr-review-toolkit:review-pr types` -- for type design problems
- `/pr-review-toolkit:review-pr comments` -- for documentation accuracy

For large PRs, run these in parallel: `/pr-review-toolkit:review-pr all parallel`

## Step 6: Apply Kiali-specific review criteria

In addition to generic code quality, check these project-specific standards:

### Go backend

- Imports organized in three groups: stdlib, third-party, kiali (`github.com/kiali/kiali/...`)
- `any` used instead of `interface{}`
- Struct fields sorted alphabetically
- No trailing whitespace on added/modified lines
- Comments explain "why", not "what"
- Error handling is present and meaningful

### TypeScript frontend

- File names: PascalCase for components, camelCase for general-purpose files
- Variables/functions: camelCase; Redux actions: PascalCase; global constants: UPPER_SNAKE_CASE
- Event handlers: `handle*` for methods, `on*` for props
- Arrow functions preferred
- All user-facing strings wrapped in `t()` from `utils/I18nUtils` (NOT from `i18next`)
- Enums use UPPER_SNAKE_CASE values

### Operator changes (if any files under `operator/` or CRD-related)

- Changes to `roles/default/` only (never modify versioned roles like `roles/v1.73/`, `roles/v2.4/`)
- CRD edits only in golden copies at `crd-docs/crd/`
- All installation methods updated: Helm charts, OLM manifests, operator templates
- Backward compatibility with older supported versions preserved

### YAML files

- Keys sorted alphabetically

### General

- No secrets or credentials committed
- No `_output/` directory changes
- No generated documentation changes

## Step 7: Produce the review report

Summarize findings with severity categories:

- **Critical**: Must fix -- security vulnerabilities, data loss, breaking changes
- **High**: Should fix before next release -- bugs, significant logic errors
- **Medium**: Should address -- code quality, missing tests, minor issues
- **Low**: Optional -- style suggestions, small improvements

For each finding, include:
- File path and line number
- What the issue is
- Why it matters
- Suggested fix (if applicable)

End with an overall assessment: is this merge safe, or are there concerns that need follow-up?
