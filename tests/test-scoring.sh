#!/usr/bin/env bash
# Golden-file scoring test runner.
# Compares score.py output against expected-scores.json for each fixture.
# Also tests edge cases inline (no fixture file needed).
set -uo pipefail
source "$(dirname "$0")/lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Fixture-based tests (single-category only) ---
echo "=== Fixture Tests ==="
for FIXTURE in "$PROJECT_DIR"/tests/fixtures/scoring-*.json; do
  NAME=$(basename "$FIXTURE" .json)
  # Skip multi-category fixtures — tested separately below
  [[ "$NAME" == *"multi"* ]] && continue
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

# --- Multi-category tests ---
echo ""
echo "=== Multi-Category Tests ==="

MULTI_RESULT=$(python3 "$PROJECT_DIR/scripts/score.py" < "$PROJECT_DIR/tests/fixtures/scoring-multi-category.json")

assert_eq "multi-aeo-score" "77" "$(echo "$MULTI_RESULT" | jq '.categories.aeo.score')"
assert_eq "multi-geo-score" "75" "$(echo "$MULTI_RESULT" | jq '.categories.geo.score')"
assert_eq "multi-seo-technical-score" "100" "$(echo "$MULTI_RESULT" | jq '.categories.seo_technical.score')"
assert_eq "multi-seo-on-page-score" "83" "$(echo "$MULTI_RESULT" | jq '.categories.seo_on_page.score')"
assert_eq "multi-structured-data-score" "50" "$(echo "$MULTI_RESULT" | jq '.categories.structured_data.score')"
assert_eq "multi-overall-score" "77" "$(echo "$MULTI_RESULT" | jq '.overall')"
assert_eq "multi-grade" '"B"' "$(echo "$MULTI_RESULT" | jq '.grade')"

# Partial category test — only AEO + GEO (weights redistributed: 50/50)
PARTIAL_RESULT=$(echo '{"categories":{"aeo":{"checks":[{"severity":"critical","result":"PASS"}]},"geo":{"checks":[{"severity":"critical","result":"FAIL"}]}}}' | python3 "$PROJECT_DIR/scripts/score.py")
assert_eq "partial-overall" "50" "$(echo "$PARTIAL_RESULT" | jq '.overall')"
assert_eq "partial-grade" '"D"' "$(echo "$PARTIAL_RESULT" | jq '.grade')"

# Grade boundary tests
assert_eq "grade-a-plus" '"A+"' "$(echo '{"categories":{"aeo":{"checks":[{"severity":"critical","result":"PASS"}]}}}' | python3 "$PROJECT_DIR/scripts/score.py" | jq '.grade')"
assert_eq "grade-f" '"F"' "$(echo '{"categories":{"aeo":{"checks":[{"severity":"critical","result":"FAIL"}]}}}' | python3 "$PROJECT_DIR/scripts/score.py" | jq '.grade')"

# --- Summary ---
test_summary
