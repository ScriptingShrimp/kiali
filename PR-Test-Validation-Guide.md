# PR Test Validation Guide

This guide provides automated checks and manual review steps to validate test file integrity in pull requests.

## Table of Contents

- [Automated Validation Checks](#automated-validation-checks)
- [Manual Review Checklist](#manual-review-checklist)
- [CI/CD Integration](#cicd-integration)
- [Common Issues to Watch For](#common-issues-to-watch-for)
- [Tools and Scripts](#tools-and-scripts)

---

## Automated Validation Checks

### 1. Validate Gherkin Feature Files

**Purpose:** Catch TypeScript/JavaScript code mistakenly placed in `.feature` files

**Command:**
```bash
# Validate all .feature files with Cucumber dry-run
find frontend/cypress/integration/featureFiles -name "*.feature" -type f | \
  xargs -I {} npx cucumber-js --dry-run {} 2>&1 | \
  grep -E "Parse error|expected.*got" && echo "❌ INVALID FEATURE FILES FOUND" || echo "✅ All feature files valid"
```

**Expected Output:**
- ✅ Success: "All feature files valid"
- ❌ Failure: Lists parse errors with file names

**Add to package.json:**
```json
{
  "scripts": {
    "validate:features": "find frontend/cypress/integration/featureFiles -name '*.feature' -exec npx cucumber-js --dry-run {} \\;",
    "test:validate": "npm run validate:features && npm run test:unit"
  }
}
```

---

### 2. Check for TypeScript/JavaScript in Feature Files

**Purpose:** Detect code patterns that shouldn't exist in Gherkin files

**Script:** `scripts/validate-feature-files.sh`
```bash
#!/bin/bash

echo "Validating feature files..."

# Find .feature files containing TypeScript/JavaScript patterns
INVALID_FILES=$(find frontend/cypress/integration/featureFiles -name "*.feature" -type f \
  -exec grep -l -E "^import |^export |^const |^let |^var |^function |^class |=>" {} \;)

if [ -n "$INVALID_FILES" ]; then
  echo "❌ ERROR: Found TypeScript/JavaScript code in .feature files:"
  echo "$INVALID_FILES"
  echo ""
  echo "Feature files should contain only Gherkin syntax (Feature, Scenario, Given, When, Then)"
  exit 1
else
  echo "✅ All feature files contain valid Gherkin syntax"
fi
```

**Usage:**
```bash
chmod +x scripts/validate-feature-files.sh
./scripts/validate-feature-files.sh
```

---

### 3. Verify Feature Files Have Gherkin Content

**Purpose:** Ensure `.feature` files start with proper Gherkin keywords

**Script:** `scripts/check-feature-structure.sh`
```bash
#!/bin/bash

echo "Checking feature file structure..."

for file in frontend/cypress/integration/featureFiles/*.feature; do
  # Check if file starts with proper Gherkin (ignoring comments and empty lines)
  FIRST_CONTENT=$(grep -v '^#' "$file" | grep -v '^$' | head -1)

  if ! echo "$FIRST_CONTENT" | grep -qE '^(Feature:|@)'; then
    echo "❌ ERROR: $file does not start with 'Feature:' or tag"
    echo "   First line: $FIRST_CONTENT"
    exit 1
  fi
done

echo "✅ All feature files have valid structure"
```

---

### 4. Validate Step Definitions Location

**Purpose:** Ensure step definitions are in correct location (`common/*.ts`), not in feature files

**Script:** `scripts/validate-step-locations.sh`
```bash
#!/bin/bash

echo "Validating step definition locations..."

# Check for step definitions in featureFiles directory (should only be in common/)
MISPLACED_STEPS=$(find frontend/cypress/integration/featureFiles -name "*.ts" -type f)

if [ -n "$MISPLACED_STEPS" ]; then
  echo "❌ ERROR: Found TypeScript files in featureFiles directory:"
  echo "$MISPLACED_STEPS"
  echo ""
  echo "Step definitions should be in: frontend/cypress/integration/common/"
  exit 1
fi

# Verify common/ directory has step definitions
COMMON_STEPS=$(find frontend/cypress/integration/common -name "*.ts" -type f | wc -l)

if [ "$COMMON_STEPS" -eq 0 ]; then
  echo "⚠️  WARNING: No step definitions found in common/ directory"
fi

echo "✅ Step definitions are in correct location"
```

---

### 5. Check for Duplicate Test Code

**Purpose:** Detect duplicate step definitions across files

**Command:**
```bash
# Find duplicate function signatures in step definitions
find frontend/cypress/integration/common -name "*.ts" -exec grep -h "^Given\|^When\|^Then" {} \; | \
  sort | uniq -d | head -10
```

If output exists, investigate for duplicates.

---

## Manual Review Checklist

### For Every PR with Test Changes

- [ ] **Feature Files (.feature)**
  - [ ] Open each `.feature` file and verify first line starts with `Feature:` or `@tag`
  - [ ] Scan for imports/exports (red flag: `import {`, `export`, `const`)
  - [ ] Verify scenarios use Gherkin syntax: `Feature`, `Scenario`, `Given`, `When`, `Then`, `And`
  - [ ] Check file size: unusually large .feature files (>500 lines) may contain code

- [ ] **Step Definitions (.ts in common/)**
  - [ ] Verify new step definitions are in `cypress/integration/common/` directory
  - [ ] Check for corresponding `.feature` file with scenarios that use these steps
  - [ ] Look for duplicate step definitions (same Given/When/Then text)

- [ ] **Unit Tests**
  - [ ] New frontend hooks have corresponding `.test.ts` files
  - [ ] New backend services have corresponding `_test.go` files
  - [ ] Test files are in same directory as code (or `__tests__` subdirectory)

- [ ] **Test Coverage**
  - [ ] Critical business logic has test coverage
  - [ ] New API endpoints have integration tests
  - [ ] Error handling paths are tested

---

## CI/CD Integration

### Pre-commit Hook (Git)

Create `.husky/pre-commit`:
```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running test validation checks..."

# Validate feature files
./scripts/validate-feature-files.sh || exit 1
./scripts/check-feature-structure.sh || exit 1
./scripts/validate-step-locations.sh || exit 1

echo "✅ All validation checks passed"
```

### GitHub Actions Workflow

Add to `.github/workflows/test-validation.yml`:
```yaml
name: Test File Validation

on:
  pull_request:
    paths:
      - 'frontend/cypress/**'
      - '**/*.test.ts'
      - '**/*.test.tsx'
      - '**/*_test.go'

jobs:
  validate-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: cd frontend && npm ci

      - name: Validate Gherkin feature files
        run: |
          npm run validate:features

      - name: Check for TypeScript in .feature files
        run: ./scripts/validate-feature-files.sh

      - name: Validate step definition locations
        run: ./scripts/validate-step-locations.sh

      - name: Check test file naming conventions
        run: |
          # Frontend: *.test.ts or *.test.tsx
          find frontend/src -name "*.test.js" -o -name "*.spec.js" | wc -l | \
            xargs -I {} test {} -eq 0 || \
            (echo "❌ Found .js test files, should be .ts or .tsx" && exit 1)

          # Backend: *_test.go (not *_spec.go)
          find . -name "*_spec.go" -not -path "*/vendor/*" | wc -l | \
            xargs -I {} test {} -eq 0 || \
            (echo "❌ Found _spec.go files, should be _test.go" && exit 1)
```

---

## Common Issues to Watch For

### 1. ✅ Correct Structure
```
cypress/
├── integration/
│   ├── featureFiles/          # ONLY .feature files (Gherkin)
│   │   ├── overview.feature   # ✅ Gherkin scenarios
│   │   └── namespaces.feature # ✅ Gherkin scenarios
│   └── common/                # ONLY .ts files (step definitions)
│       ├── overview.ts        # ✅ TypeScript step definitions
│       └── namespaces.ts      # ✅ TypeScript step definitions
```

### 2. ❌ Wrong Structure (PR #9151 issue)
```
cypress/
├── integration/
│   ├── featureFiles/
│   │   └── overview.feature   # ❌ Contains TypeScript instead of Gherkin
│   └── common/
│       └── overview.ts        # ✅ Correct, but now duplicated above
```

### 3. Valid Feature File Example
```gherkin
@overview
Feature: Overview Dashboard

  User views the overview dashboard

  Background:
    Given user is at the "overview" page

  Scenario: View clusters card
    Then Clusters card shows cluster count
```

### 4. Invalid Feature File (Red Flags)
```typescript
import { Given, When, Then } from '@badeball/cypress-cucumber-preprocessor';  // ❌

const APP_RATES_API = '**/api/overview/metrics/apps/rates';  // ❌

Given('user is at the overview page', () => {  // ❌
  cy.visit('/overview');
});
```

---

## Tools and Scripts

### Quick Validation Command

Add to `package.json`:
```json
{
  "scripts": {
    "pr:validate": "npm run validate:features && npm run validate:tests && npm run validate:structure",
    "validate:features": "./scripts/validate-feature-files.sh && ./scripts/check-feature-structure.sh",
    "validate:tests": "./scripts/check-test-coverage.sh",
    "validate:structure": "./scripts/validate-step-locations.sh"
  }
}
```

**Usage before creating PR:**
```bash
npm run pr:validate
```

---

### Coverage Report for New Code

```bash
# Frontend unit test coverage
cd frontend && npm run test:coverage

# Backend test coverage
go test -cover ./... | grep -v "no test files"

# Show untested files
go test -cover ./... | grep "0.0%"
```

---

### File Pattern Validation

**Command to validate all test files:**
```bash
# Check .feature files are valid Gherkin
find . -name "*.feature" -type f | while read file; do
  if head -20 "$file" | grep -qE "^import |^const |^let "; then
    echo "❌ $file contains code instead of Gherkin"
  fi
done

# Check .test.ts files exist for new hooks
find frontend/src/hooks -name "*.ts" ! -name "*.test.ts" | while read hook; do
  test_file="${hook%.ts}.test.ts"
  if [ ! -f "$test_file" ]; then
    echo "⚠️  Missing test: $test_file"
  fi
done

# Check _test.go files exist for new services
find business -name "*.go" ! -name "*_test.go" ! -name "*_mock.go" | while read svc; do
  test_file="${svc%.go}_test.go"
  if [ ! -f "$test_file" ]; then
    echo "⚠️  Missing test: $test_file"
  fi
done
```

---

## Integration with PR Review Process

### 1. Add to CLAUDE.md

Update the review guidelines section:
```markdown
## PR Review Checklist - Test Validation

Before approving PRs with test changes:

1. **Validate Feature Files**
   ```bash
   npm run validate:features
   ```

2. **Check for Code in Feature Files**
   ```bash
   ./scripts/validate-feature-files.sh
   ```

3. **Verify Test Coverage**
   - Run `npm run test:coverage` for frontend changes
   - Run `go test -cover ./...` for backend changes

4. **Manual Inspection**
   - Open `.feature` files and verify they contain Gherkin, not code
   - Check new hooks have `.test.ts` files
   - Check new services have `_test.go` files
```

### 2. Add to PR Template

Create `.github/pull_request_template.md`:
```markdown
## Test Validation Checklist

- [ ] Ran `npm run pr:validate` and all checks passed
- [ ] Verified `.feature` files contain only Gherkin syntax
- [ ] New code has corresponding unit tests
- [ ] All tests pass locally

## For PRs with Cypress Changes

- [ ] Step definitions are in `cypress/integration/common/*.ts`
- [ ] Feature files are in `cypress/integration/featureFiles/*.feature`
- [ ] Feature files start with `Feature:` keyword
- [ ] No TypeScript imports in `.feature` files
```

---

## Recommended Workflow

### For PR Authors (Before Submitting)

```bash
# 1. Validate all test files
npm run pr:validate

# 2. Run tests
npm test
cd frontend && npm test

# 3. Check coverage for new code
npm run test:coverage

# 4. Manually review feature files
git diff --name-only | grep ".feature$" | xargs cat | head -50
```

### For PR Reviewers

```bash
# 1. Quick validation
npm run validate:features
./scripts/validate-feature-files.sh

# 2. Check what changed
git diff main...HEAD --name-only | grep -E ".feature$|.test.ts$|_test.go$"

# 3. Review changed test files
git diff main...HEAD -- "*.feature" "*.test.ts" "*_test.go"

# 4. Look for missing tests
./scripts/check-test-coverage.sh
```

---

## Specific Check for PR #9151 Issue

**Problem:** TypeScript code in `overview.feature` instead of Gherkin

**Detection Command:**
```bash
# Check if overview.feature has invalid content
if grep -q "^import {" frontend/cypress/integration/featureFiles/overview.feature; then
  echo "❌ CRITICAL: overview.feature contains TypeScript imports"
  echo "   This file should contain only Gherkin scenarios"
  exit 1
fi

# Verify it starts with proper Gherkin
if ! head -5 frontend/cypress/integration/featureFiles/overview.feature | grep -qE "^Feature:|^@"; then
  echo "❌ ERROR: overview.feature does not start with Feature: or @tag"
  exit 1
fi
```

**Add to CI:**
```yaml
- name: Validate overview.feature specifically
  run: |
    if grep -q "^import {" frontend/cypress/integration/featureFiles/overview.feature; then
      echo "❌ overview.feature contains TypeScript (see PR #9151 issue)"
      exit 1
    fi
```

---

## Summary

**Priority Actions:**

1. **Immediate** - Create validation scripts:
   - `scripts/validate-feature-files.sh`
   - `scripts/check-feature-structure.sh`
   - `scripts/validate-step-locations.sh`

2. **This Week** - Add to CI/CD:
   - GitHub Actions workflow for test validation
   - Pre-commit hooks

3. **Before Next PR** - Update documentation:
   - Add test validation section to CLAUDE.md
   - Create PR template with test checklist

4. **Ongoing** - Manual reviews:
   - Always open `.feature` files in PR diff
   - Check for `import` statements in Gherkin files
   - Verify new code has tests

**Key Commands to Remember:**
```bash
# Validate before creating PR
npm run pr:validate

# Quick feature file check
find . -name "*.feature" | xargs grep "^import " && echo "❌ FOUND CODE" || echo "✅ OK"

# Validate with Cucumber
npx cucumber-js --dry-run cypress/integration/featureFiles/*.feature
```
