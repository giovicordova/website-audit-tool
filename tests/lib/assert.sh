#!/bin/bash
# Shared test assertion helpers.
# Source this file at the top of each test script:
#   source "$(dirname "$0")/lib/assert.sh"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $label"; ((PASS++)) || true
  else
    echo "FAIL: $label (expected=$expected, actual=$actual)"; ((FAIL++)) || true
  fi
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "PASS: $label"; ((PASS++)) || true
  else
    echo "FAIL: $label (expected to contain '$needle')"; ((FAIL++)) || true
  fi
}

test_summary() {
  echo ""
  echo "$PASS passed, $FAIL failed"
  [[ "$FAIL" -eq 0 ]]
}
