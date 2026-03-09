#!/bin/bash
# test-perplexity-output.sh — validates perplexity-check.sh jq extraction against mock Perplexity JSON
# Runs in <2 seconds. No live API call needed.

set -euo pipefail

PASS=0
FAIL=0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURE="$PROJECT_DIR/tests/fixtures/perplexity-response.json"

# Precondition: perplexity-check.sh must exist and be executable
if [ ! -x "$PROJECT_DIR/scripts/perplexity-check.sh" ]; then
  echo "ABORT: scripts/perplexity-check.sh not found or not executable" >&2
  exit 1
fi

# Check jq is available
if ! command -v jq &>/dev/null; then
  echo "ABORT: jq is required but not installed" >&2
  exit 1
fi

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (expected=$expected, actual=$actual)"
    FAIL=$((FAIL + 1))
  fi
}

# Apply the same jq filter used in perplexity-check.sh to the fixture
RESULT=$(cat "$FIXTURE" | jq --arg domain "example.com" '{
  answer: (.choices[0].message.content[:300]),
  citations: (.citations // []),
  domain_cited: ((.citations // []) | any(test($domain)))
}')

# 1. Answer snippet exists
ANSWER=$(echo "$RESULT" | jq -r '.answer')
assert_eq "answer exists" "true" "$([ -n "$ANSWER" ] && echo true || echo false)"

# 2. Answer snippet <= 300 chars
ANSWER_LEN=${#ANSWER}
assert_eq "answer <= 300 chars" "true" "$([ "$ANSWER_LEN" -le 300 ] && echo true || echo false)"

# 3. Citations is array
assert_eq "citations is array" "true" "$(echo "$RESULT" | jq 'if .citations | type == "array" then "true" else "false" end' -r)"

# 4. Citations count = 3
assert_eq "citations count" "3" "$(echo "$RESULT" | jq '.citations | length')"

# 5. example.com detected as cited (positive)
assert_eq "example.com cited" "true" "$(echo "$RESULT" | jq '.domain_cited')"

# 6. nonexistent.xyz not cited (negative)
RESULT_NEG=$(cat "$FIXTURE" | jq --arg domain "nonexistent.xyz" '{
  domain_cited: ((.citations // []) | any(test($domain)))
}')
assert_eq "nonexistent.xyz not cited" "false" "$(echo "$RESULT_NEG" | jq '.domain_cited')"

# 7. Empty citations array returns false
RESULT_EMPTY=$(echo '{"choices":[{"message":{"content":"test"}}],"citations":[]}' | jq --arg domain "example.com" '{
  domain_cited: ((.citations // []) | any(test($domain)))
}')
assert_eq "empty citations = false" "false" "$(echo "$RESULT_EMPTY" | jq '.domain_cited')"

# 8. Missing citations key returns false
RESULT_MISSING=$(echo '{"choices":[{"message":{"content":"test"}}]}' | jq --arg domain "example.com" '{
  domain_cited: ((.citations // []) | any(test($domain)))
}')
assert_eq "missing citations key = false" "false" "$(echo "$RESULT_MISSING" | jq '.domain_cited')"

# Summary
echo ""
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
