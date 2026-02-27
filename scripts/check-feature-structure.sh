#!/bin/bash

# Verify that .feature files have proper Gherkin structure
# Files should start with Feature: or @tag

set -e

echo "🔍 Checking feature file structure..."

FEATURE_DIR="frontend/cypress/integration/featureFiles"
ERRORS_FOUND=0

# Check if directory exists
if [ ! -d "$FEATURE_DIR" ]; then
  echo "⚠️  Warning: $FEATURE_DIR not found, skipping validation"
  exit 0
fi

for file in "$FEATURE_DIR"/*.feature; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")

    # Get first non-comment, non-empty line
    FIRST_CONTENT=$(grep -v '^#' "$file" | grep -v '^$' | head -1 | xargs)

    # Check if it starts with Feature: or @tag
    if ! echo "$FIRST_CONTENT" | grep -qE '^(Feature:|@)'; then
      echo "❌ ERROR: $filename does not start with 'Feature:' or '@tag'"
      echo "   First content line: '$FIRST_CONTENT'"
      ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi

    # Check if Feature: keyword exists anywhere in file
    if ! grep -qE '^Feature:' "$file"; then
      echo "❌ ERROR: $filename does not contain 'Feature:' keyword"
      ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi

    # Warn if file has no scenarios
    if ! grep -qE '^  Scenario:' "$file"; then
      echo "⚠️  WARNING: $filename has no scenarios (Feature without test cases)"
    fi
  fi
done

if [ $ERRORS_FOUND -gt 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ VALIDATION FAILED: Found $ERRORS_FOUND file(s) with invalid structure"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Valid feature file structure:"
  echo ""
  echo "  @tag1"
  echo "  @tag2"
  echo "  Feature: Feature name"
  echo ""
  echo "    Description of the feature"
  echo ""
  echo "    Scenario: Scenario name"
  echo "      Given some precondition"
  echo "      When some action"
  echo "      Then some assertion"
  echo ""
  exit 1
else
  echo "✅ All feature files have valid Gherkin structure"
  exit 0
fi
