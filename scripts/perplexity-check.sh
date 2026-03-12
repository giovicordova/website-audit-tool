#!/bin/bash
# Usage: perplexity-check.sh <query> <domain>
# Returns: JSON on stdout with answer snippet, citations, and domain_cited boolean
# On error: JSON with "error" key on stdout, exit 1
# Requires PERPLEXITY_API_KEY env var.

set -euo pipefail

QUERY="$1"
DOMAIN="$2"

if [ -z "$QUERY" ] || [ -z "$DOMAIN" ]; then
  echo '{"error": "Usage: perplexity-check.sh <query> <domain>"}'
  exit 1
fi

if [ -z "${PERPLEXITY_API_KEY:-}" ]; then
  echo '{"error": "PERPLEXITY_API_KEY not set"}'
  exit 1
fi

# Dependency checks
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq not found — install jq"}'
  exit 1
fi

if ! command -v curl &>/dev/null; then
  echo '{"error": "curl not found"}'
  exit 1
fi

RESPONSE=$(curl --max-time 30 -s -w "\n%{http_code}" \
  -X POST "https://api.perplexity.ai/chat/completions" \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg q "$QUERY" '{
    model: "sonar",
    messages: [{role: "user", content: $q}],
    return_citations: true
  }')")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
  echo "{\"error\": \"HTTP $HTTP_CODE\", \"body\": $(echo "$BODY" | jq -R -s '.')}"
  exit 1
fi

# Extract answer (capped at 300 chars), citations array, and domain_cited boolean
echo "$BODY" | jq --arg domain "$DOMAIN" '{
  answer: (.choices[0].message.content[:300]),
  citations: (.citations // []),
  domain_cited: ((.citations // []) | any(test($domain)))
}'
