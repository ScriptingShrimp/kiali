# Test Validation Setup - Summary

## Created Files

### 1. Documentation
- ✅ **PR-Test-Validation-Guide.md** - Comprehensive guide for test validation
- ✅ **TEST-VALIDATION-SETUP-SUMMARY.md** - This summary document
- ✅ **CLAUDE.md** - Updated with test validation section

### 2. Validation Scripts
- ✅ **scripts/validate-feature-files.sh** - Detects TypeScript code in .feature files
- ✅ **scripts/check-feature-structure.sh** - Validates Gherkin file structure
- ✅ **scripts/validate-step-locations.sh** - Checks file organization

### 3. Updated Review Report
- ✅ **PR-9151-Review.md** - Added critical issue #1 (invalid overview.feature)

---

## Verification - Scripts Working ✅

All validation scripts successfully detect the PR #9151 issue:

```bash
$ ./scripts/validate-feature-files.sh
❌ VALIDATION FAILED: Found 4 file(s) with invalid content
- overview.feature contains import/export statements
- overview.feature contains variable declarations (const/let/var)
- overview.feature contains function/class declarations
- overview.feature contains TypeScript type annotations

$ ./scripts/check-feature-structure.sh
❌ VALIDATION FAILED: Found 2 file(s) with invalid structure
- overview.feature does not start with 'Feature:' or '@tag'
- overview.feature does not contain 'Feature:' keyword

$ ./scripts/validate-step-locations.sh
✅ Step definitions are in correct location (46 files in common/)
```

---

## Quick Start Guide

### For PR Authors

**Before committing test changes:**
```bash
./scripts/validate-feature-files.sh
./scripts/check-feature-structure.sh
./scripts/validate-step-locations.sh
```

### For PR Reviewers

**Quick validation:**
```bash
./scripts/validate-feature-files.sh
```

**Review test file changes:**
```bash
git diff main...HEAD -- "*.feature" "*.test.ts" "*_test.go"
```

---

## Recommended Next Steps

### Immediate (Fix Current Issue)

1. **Fix overview.feature file**
   ```bash
   # Remove TypeScript content, add Gherkin scenarios
   # See PR-9151-Review.md issue #1 for details
   ```

### This Week (Automation)

2. **Add validation to package.json**
   ```json
   {
     "scripts": {
       "validate:tests": "npm run validate:features && npm run validate:structure",
       "validate:features": "./scripts/validate-feature-files.sh && ./scripts/check-feature-structure.sh",
       "validate:structure": "./scripts/validate-step-locations.sh",
       "pretest": "npm run validate:tests"
     }
   }
   ```

3. **Add pre-commit hook**
   ```bash
   # Install husky
   npm install --save-dev husky
   npx husky install

   # Create pre-commit hook
   npx husky add .husky/pre-commit "./scripts/validate-feature-files.sh"
   ```

4. **Create GitHub Actions workflow**
   - See `PR-Test-Validation-Guide.md` section "CI/CD Integration"
   - Add `.github/workflows/test-validation.yml`

### Within 2 Weeks (Process)

5. **Update PR template**
   - Create `.github/pull_request_template.md`
   - Include test validation checklist

6. **Document in team wiki**
   - Share validation guide with team
   - Add to onboarding documentation

---

## Best Practices Established

### ✅ DO

- **Keep .feature files pure Gherkin** (Feature, Scenario, Given, When, Then)
- **Put step definitions in common/*.ts** (TypeScript implementation)
- **Run validation scripts before creating PR**
- **Add unit tests for new hooks and services**
- **Verify test coverage for critical logic**

### ❌ DON'T

- **Never put TypeScript/JavaScript in .feature files**
- **Never put .ts files in featureFiles/ directory**
- **Never skip test validation before submitting PR**
- **Never create features without corresponding test scenarios**

---

## File Organization Reference

```
✅ CORRECT STRUCTURE:

kiali/
├── frontend/
│   └── cypress/
│       └── integration/
│           ├── featureFiles/              # ONLY .feature files
│           │   ├── overview.feature       # Gherkin scenarios
│           │   ├── namespaces.feature     # Gherkin scenarios
│           │   └── apps.feature           # Gherkin scenarios
│           └── common/                    # ONLY .ts files
│               ├── overview.ts            # Step definitions
│               ├── namespaces.ts          # Step definitions
│               └── apps.ts                # Step definitions
├── scripts/
│   ├── validate-feature-files.sh          # Validation scripts
│   ├── check-feature-structure.sh
│   └── validate-step-locations.sh
└── CLAUDE.md                               # Updated with test validation

❌ WRONG (PR #9151 issue):

featureFiles/
└── overview.feature    # Contains TypeScript instead of Gherkin ❌
```

---

## Validation Script Details

### validate-feature-files.sh

**Detects:**
- `import` / `export` statements
- Variable declarations (`const`, `let`, `var`)
- Function/class declarations
- Promise chains (`.then()`, `.catch()`)
- TypeScript type annotations

**Exit codes:**
- 0 = All valid
- 1 = Invalid files found

### check-feature-structure.sh

**Validates:**
- First line is `Feature:` or `@tag`
- File contains `Feature:` keyword
- File has scenarios

**Warnings:**
- Files without scenarios

### validate-step-locations.sh

**Checks:**
- No `.ts` files in `featureFiles/`
- Step definitions exist in `common/`
- Reports count of step definition files

---

## Testing the Scripts

### Manual Test

```bash
# Should fail on current codebase (overview.feature is invalid)
./scripts/validate-feature-files.sh
# Expected: Exit code 1, error messages about overview.feature

# Should also fail on structure check
./scripts/check-feature-structure.sh
# Expected: Exit code 1, missing Feature: keyword

# Should pass for location check
./scripts/validate-step-locations.sh
# Expected: Exit code 0, 46 step files found
```

### Integration Test

```bash
# Run all validations
for script in scripts/validate-*.sh scripts/check-*.sh; do
  echo "Running $script..."
  $script
  echo "Exit code: $?"
  echo "---"
done
```

---

## Common Validation Failures

### Issue: "Contains import/export statements"

**Cause:** TypeScript code in .feature file

**Fix:**
1. Move TypeScript code to `common/*.ts`
2. Replace with Gherkin scenarios in .feature file

**Example:**
```bash
# Before (WRONG)
# overview.feature:
import { Given } from '@badeball/cypress-cucumber-preprocessor';

# After (CORRECT)
# overview.feature:
@overview
Feature: Overview Dashboard
  Scenario: View clusters
    Given user is at the "overview" page

# common/overview.ts:
import { Given } from '@badeball/cypress-cucumber-preprocessor';
Given('user is at the {string} page', (page) => { /* ... */ });
```

### Issue: "Does not start with Feature: or @tag"

**Cause:** File missing proper Gherkin header

**Fix:** Add Feature declaration:
```gherkin
@tag
Feature: Feature Name
  Description here
```

### Issue: "Found TypeScript files in featureFiles"

**Cause:** `.ts` file in wrong directory

**Fix:** Move to `common/` directory:
```bash
mv frontend/cypress/integration/featureFiles/overview.ts \
   frontend/cypress/integration/common/overview.ts
```

---

## Metrics & Monitoring

### Track Validation Success Rate

```bash
# Count invalid feature files
INVALID_COUNT=$(./scripts/validate-feature-files.sh 2>&1 | grep -c "ERROR:")

# Count total feature files
TOTAL_COUNT=$(find frontend/cypress/integration/featureFiles -name "*.feature" | wc -l)

# Calculate success rate
echo "Valid: $(($TOTAL_COUNT - $INVALID_COUNT / 4)) / $TOTAL_COUNT"
```

### CI/CD Metrics to Track

- Number of PRs blocked by validation
- Time saved catching issues early
- Reduction in test-related PR comments

---

## Support & Troubleshooting

### Script Fails with "Permission denied"

```bash
chmod +x scripts/*.sh
```

### Script Shows Wrong Results

```bash
# Ensure you're in project root
cd /path/to/kiali

# Re-run scripts
./scripts/validate-feature-files.sh
```

### False Positives

If scripts incorrectly flag valid Gherkin:
1. Check for syntax that looks like code (e.g., `=>` in scenario name)
2. Update regex patterns in scripts if needed
3. Report issue for script improvement

---

## Integration with Code Review Tools

### Danger.js Integration (Optional)

```javascript
// dangerfile.js
import { danger, warn, fail } from 'danger';

// Check for TypeScript in feature files
const featureFiles = danger.git.modified_files.filter(f => f.endsWith('.feature'));
for (const file of featureFiles) {
  const content = danger.github.utils.fileContents(file);
  if (content.includes('import {') || content.includes('const ')) {
    fail(`${file} contains TypeScript code instead of Gherkin scenarios`);
  }
}
```

### GitHub Bot Comment (Optional)

Add to CI to comment on PRs:
```yaml
- name: Comment on PR if validation fails
  if: failure()
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: '❌ Test validation failed. Please run `./scripts/validate-feature-files.sh` locally and fix issues.'
      })
```

---

## Success Criteria

### Short Term (1 week)
- ✅ Scripts created and executable
- ✅ Documentation updated
- ✅ Scripts detect PR #9151 issue
- ⏳ overview.feature fixed
- ⏳ Scripts added to package.json

### Medium Term (2 weeks)
- ⏳ CI/CD integration active
- ⏳ Pre-commit hooks installed
- ⏳ Team trained on validation process
- ⏳ PR template updated

### Long Term (1 month)
- ⏳ Zero invalid test files in new PRs
- ⏳ Reduced test-related PR comments
- ⏳ Improved test quality metrics

---

## References

- [PR-Test-Validation-Guide.md](./PR-Test-Validation-Guide.md) - Full validation guide
- [PR-9151-Review.md](./PR-9151-Review.md) - Detailed PR review with issue #1
- [CLAUDE.md](./CLAUDE.md) - Updated project guidelines
- [Cucumber Gherkin Reference](https://cucumber.io/docs/gherkin/reference/)

---

**Created:** 2026-02-25
**Author:** Claude Code (AI-assisted)
**Status:** ✅ Ready for implementation
