#!/bin/bash

# Validate that .feature files contain only Gherkin syntax, not TypeScript/JavaScript code
# This prevents issues like PR #9151 where TypeScript was mistakenly placed in overview.feature

set -e

echo "🔍 Validating feature files for invalid code patterns..."

FEATURE_DIR="frontend/cypress/integration/featureFiles"
ERRORS_FOUND=0

# Check if directory exists
if [ ! -d "$FEATURE_DIR" ]; then
  echo "⚠️  Warning: $FEATURE_DIR not found, skipping validation"
  exit 0
fi

# Find .feature files containing TypeScript/JavaScript patterns
echo "Checking for TypeScript/JavaScript imports and syntax..."

for file in "$FEATURE_DIR"/*.feature; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")

    # Check for TypeScript/JavaScript imports
    if grep -qE "^import |^export " "$file"; then
      echo "❌ ERROR: $filename contains import/export statements"
      ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi

    # Check for JavaScript variable declarations
    if grep -qE "^const |^let |^var " "$file"; then
      echo "❌ ERROR: $filename contains variable declarations (const/let/var)"
      ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi

    # Check for function declarations
    if grep -qE "^function |^class |=>|\\.then\(|\.catch\(" "$file"; then
      echo "❌ ERROR: $filename contains function/class declarations or promises"
      ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi

    # Check for TypeScript type annotations
    if grep -qE ": (string|number|boolean|any|void)\s*[;=]" "$file"; then
      echo "❌ ERROR: $filename contains TypeScript type annotations"
      ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi
  fi
done

if [ $ERRORS_FOUND -gt 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ VALIDATION FAILED: Found $ERRORS_FOUND file(s) with invalid content"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Feature files should contain ONLY Gherkin syntax:"
  echo "  - Feature: <description>"
  echo "  - Scenario: <description>"
  echo "  - Given/When/Then/And/But steps"
  echo "  - @tags"
  echo "  - Comments (#)"
  echo ""
  echo "Step definitions (TypeScript/JavaScript) should be in:"
  echo "  frontend/cypress/integration/common/*.ts"
  echo ""
  echo "See PR #9151 for example of this issue."
  exit 1
else
  echo "✅ All feature files contain valid Gherkin syntax"
  exit 0
fi
