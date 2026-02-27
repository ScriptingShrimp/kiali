# Kiali Project Guidelines for AI Assistants

This document provides context and guidelines for AI assistants working on the Kiali project.

## Project Overview

Kiali is a management console for Istio service mesh. It provides observability into the structure and health of the service mesh by inferring traffic topology and displaying service mesh configuration. The project is CNCF-aligned and part of the Istio ecosystem.

**Repository Structure:**
- `/frontend` - React/TypeScript UI application
- `/business` - Go backend business logic
- `/config` - Configuration handling
- `/kubernetes` - Kubernetes API interactions
- `/models` - Data models
- `/handlers` - HTTP request handlers
- `/graph` - Service mesh graph generation
- `/prometheus` - Prometheus integration

## Code Style Standards

### Backend (Go)

**Import Organization:**
```go
import (
    // Standard library imports
    "errors"
    "fmt"

    // Third-party imports
    "k8s.io/client-go/tools/clientcmd/api"

    // Kiali imports
    "github.com/kiali/kiali/log"
)
```

**Struct Fields:**
- ALL struct fields MUST be in alphabetical order (both public and private)
- This applies to both type definitions and struct initialization

```go
type MyStruct struct {
    Alpha   string
    Beta    int
    Gamma   bool
    delta   time.Time  // private fields also alphabetical
    epsilon float64
}
```

**Formatting:**
- Use `gofmt` for consistent formatting
- Run `golint` and `govet` for static analysis

### Frontend (TypeScript)

**Naming Conventions:**
- Files: `PascalCase` for files exporting types/classes (e.g., `ServiceList.ts`)
- General purpose files: `camelCase` (e.g., `routes.ts`)
- Variables/functions: `camelCase`
- Redux actions: `PascalCase` (e.g., `GraphActions`)
- Global constants: `UPPER_SNAKE_CASE`
- Enum names: `PascalCase`, values: `UPPER_SNAKE_CASE`

```typescript
enum DisplayMode {
  LARGE,
  SMALL
}
```

**Event Handlers:**
- Begin with `handle`
- End with event name (e.g., `handleClick`, `handleChange`)
- Use present tense
- Props should start with `on` (e.g., `onSelect`)

**Redux Props Pattern:**
```typescript
type ReduxProps = {
  // Redux props only, alphabetical
};

type ComponentNameProps = ReduxProps & {
  // non-Redux props, alphabetical
};

class ComponentName extends React.Component<ComponentNameProps> {
  // ...
}
```

**Arrow Functions:**
- Prefer arrow functions (fat arrow) for consistency

## AI-Assisted Development Requirements

**MANDATORY Disclosures:**

All AI-assisted contributions MUST include disclosure in:

1. **Commit messages and PRs:**
```
Assisted-by: Claude Code
```
or
```
Generated-by: <AI tool name>
```

2. **Source file comments:**
```go
// Assisted-by: Claude Code
```
or
```typescript
// Generated-by: Cursor
```

**Required Practices:**
- Thoroughly review and understand all AI-generated code
- Be able to explain and defend implementation in code reviews
- Verify license compliance (Apache 2.0)
- Test thoroughly - all tests must pass
- Ensure security best practices
- No blind copy-paste submissions

**Prohibited:**
- Submitting code you cannot explain
- License violations
- Security vulnerabilities
- Gaming contribution metrics
- Misrepresenting code origin

See [AI_POLICY.md](./AI_POLICY.md) for complete guidelines.

## Quality Standards

**Testing:**
- All code changes require appropriate test coverage
- Tests must pass before submission
- UI changes should include screenshots

**Security:**
- No command injection vulnerabilities
- No XSS vulnerabilities
- No SQL injection vulnerabilities
- Follow OWASP top 10 guidelines
- Proper handling of secrets and credentials

**Code Review:**
- All PRs require maintainer review
- Be responsive to feedback
- Iterate based on review comments
- Link related GitHub issues in PR description

## Development Workflow

1. Open a [discussion](https://github.com/kiali/kiali/discussions) or [issue](https://github.com/kiali/kiali/issues)
2. Wait for maintainer agreement before starting work
3. Develop following style guidelines
4. Test thoroughly
5. Submit PR with detailed explanation
6. Include AI disclosure if applicable
7. Respond to review feedback

## Project-Specific Patterns and Conventions

<!-- This section will be expanded with project-specific patterns as they are identified -->

### To Be Added:
- Common error handling patterns
- Preferred logging practices
- API versioning approach
- Database interaction patterns
- Service mesh integration patterns
- Testing patterns and utilities

## Test Validation

**IMPORTANT:** All PRs with test changes must pass validation checks to ensure test file integrity.

### Automated Checks (Run Before Creating PR)

```bash
# Validate all test files
./scripts/validate-feature-files.sh   # Check for TypeScript in .feature files
./scripts/check-feature-structure.sh  # Verify Gherkin structure
./scripts/validate-step-locations.sh  # Ensure correct file organization
```

### Critical Rules

1. **Cypress Feature Files (.feature)**
   - MUST contain ONLY Gherkin syntax (Feature, Scenario, Given, When, Then)
   - MUST NOT contain TypeScript/JavaScript code (import, const, function, etc.)
   - MUST start with `Feature:` or `@tag`
   - Location: `frontend/cypress/integration/featureFiles/*.feature`

2. **Cypress Step Definitions (.ts)**
   - MUST contain TypeScript step implementation code
   - MUST be in `frontend/cypress/integration/common/*.ts`
   - MUST NOT be in `featureFiles/` directory

3. **Unit Tests**
   - Frontend hooks → `*.test.ts` in same directory
   - Backend services → `*_test.go` in same directory
   - Required for all new business logic

### Common Test File Issues

❌ **INVALID** - TypeScript in .feature file (See PR #9151):
```typescript
// frontend/cypress/integration/featureFiles/overview.feature
import { Given, When, Then } from '@badeball/cypress-cucumber-preprocessor';
const API_URL = '**/api/overview';
Given('user is at overview page', () => { /* ... */ });
```

✅ **VALID** - Gherkin in .feature file:
```gherkin
@overview
Feature: Overview Dashboard

  Scenario: View clusters card
    Given user is at the "overview" page
    Then Clusters card shows cluster count
```

### Test Validation Workflow

**For PR Authors:**
```bash
# Before committing test changes
./scripts/validate-feature-files.sh
./scripts/check-feature-structure.sh

# Run tests
npm test
cd frontend && npm test
```

**For PR Reviewers:**
```bash
# Quick validation
./scripts/validate-feature-files.sh

# Review test file changes
git diff main...HEAD -- "*.feature" "*.test.ts" "*_test.go"
```

See [PR-Test-Validation-Guide.md](./PR-Test-Validation-Guide.md) for comprehensive testing guidelines.

---

## References

- [CONTRIBUTING.md](./CONTRIBUTING.md) - Contribution workflow
- [STYLE_GUIDE.adoc](./STYLE_GUIDE.adoc) - Detailed style guide
- [AI_POLICY.md](./AI_POLICY.md) - AI usage policy
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) - Community standards
- [PR-Test-Validation-Guide.md](./PR-Test-Validation-Guide.md) - Test validation procedures
