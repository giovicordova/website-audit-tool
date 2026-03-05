#!/usr/bin/env bash
# Golden-file scoring test runner.
# Compares score.py output against expected-scores.json for each fixture.
# Also tests edge cases inline (no fixture file needed).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# --- Fixture-based tests ---
echo "=== Fixture Tests ==="
for FIXTURE in "$PROJECT_DIR"/tests/fixtures/scoring-*.json; do
  NAME=$(basename "$FIXTURE" .json)
  ACTUAL=$(python3 "$PROJECT_DIR/scripts/score.py" < "$FIXTURE")
  EXPECTED=$(jq -r ".\"$NAME\"" "$PROJECT_DIR/tests/fixtures/expected-scores.json")
  assert_eq "$NAME" "$EXPECTED" "$ACTUAL"
done

# --- Edge case tests (inline) ---
echo ""
echo "=== Edge Case Tests ==="

# Empty checks array should return 100 (no testable checks = perfect)
ACTUAL=$(echo '{"checks":[]}' | python3 "$PROJECT_DIR/scripts/score.py")
assert_eq "empty-checks-returns-100" "100" "$ACTUAL"

# Single WARNING on nice_to_have: floor(1*0.5)=0 earned, 1 possible = 0/1 = 0%
ACTUAL=$(echo '{"checks":[{"severity":"nice_to_have","result":"WARNING"}]}' | python3 "$PROJECT_DIR/scripts/score.py")
assert_eq "nice-warning-floors-to-zero" "0" "$ACTUAL"

# --- Summary ---
echo ""
echo "$PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
