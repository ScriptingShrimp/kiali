#!/bin/bash

# Validate that step definitions are in correct location
# - Step definitions (.ts files) should be in: cypress/integration/common/
# - NOT in: cypress/integration/featureFiles/

set -e

echo "🔍 Validating step definition locations..."

FEATURE_DIR="frontend/cypress/integration/featureFiles"
COMMON_DIR="frontend/cypress/integration/common"
ERRORS_FOUND=0

# Check for TypeScript files in featureFiles directory (wrong location)
if [ -d "$FEATURE_DIR" ]; then
  MISPLACED_STEPS=$(find "$FEATURE_DIR" -name "*.ts" -o -name "*.tsx" -o -name "*.js" 2>/dev/null)

  if [ -n "$MISPLACED_STEPS" ]; then
    echo "❌ ERROR: Found TypeScript/JavaScript files in featureFiles directory:"
    echo "$MISPLACED_STEPS" | while read -r file; do
      echo "   - $file"
    done
    echo ""
    echo "Step definitions should be in: $COMMON_DIR/"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
  fi
fi

# Verify common/ directory exists and has step definitions
if [ ! -d "$COMMON_DIR" ]; then
  echo "⚠️  WARNING: $COMMON_DIR directory not found"
else
  COMMON_STEPS=$(find "$COMMON_DIR" -name "*.ts" 2>/dev/null | wc -l | xargs)

  if [ "$COMMON_STEPS" -eq 0 ]; then
    echo "⚠️  WARNING: No step definitions (*.ts) found in $COMMON_DIR"
  else
    echo "ℹ️  Found $COMMON_STEPS step definition file(s) in $COMMON_DIR"
  fi
fi

if [ $ERRORS_FOUND -gt 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ VALIDATION FAILED: Step definitions in wrong location"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Correct structure:"
  echo "  cypress/integration/"
  echo "  ├── featureFiles/     ← ONLY .feature files (Gherkin scenarios)"
  echo "  └── common/           ← ONLY .ts files (step definitions)"
  echo ""
  exit 1
else
  echo "✅ Step definitions are in correct location"
  exit 0
fi
