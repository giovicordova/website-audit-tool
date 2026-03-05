#!/usr/bin/env bash
# Unit test: verify score.py produces correct scores for each fixture
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $label"; ((PASS++))
  else
    echo "FAIL: $label (expected=$expected, actual=$actual)"; ((FAIL++))
  fi
}

# Test each fixture against expected scores
for FIXTURE in "$PROJECT_DIR"/tests/fixtures/scoring-*.json; do
  NAME=$(basename "$FIXTURE" .json)
  ACTUAL=$(python3 "$PROJECT_DIR/scripts/score.py" < "$FIXTURE")
  EXPECTED=$(jq -r ".\"$NAME\"" "$PROJECT_DIR/tests/fixtures/expected-scores.json")
  assert_eq "$NAME" "$EXPECTED" "$ACTUAL"
done

echo ""
echo "$PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
