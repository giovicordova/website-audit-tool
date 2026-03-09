#!/bin/bash
# Usage: perplexity-check.sh <query> <domain>
# Returns: JSON with answer snippet, citations, and domain_cited boolean
# Requires PERPLEXITY_API_KEY env var.

QUERY="$1"
DOMAIN="$2"

if [ -z "$QUERY" ] || [ -z "$DOMAIN" ]; then
  echo '{"error": "Usage: perplexity-check.sh <query> <domain>"}' >&2
  exit 1
fi

if [ -z "$PERPLEXITY_API_KEY" ]; then
  echo '{"error": "PERPLEXITY_API_KEY not set"}' >&2
  exit 1
fi

# Check jq is available
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq is required but not installed"}' >&2
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
  echo "{\"error\": \"HTTP $HTTP_CODE\", \"body\": $(echo "$BODY" | jq -R -s '.')}" >&2
  exit 1
fi

# Extract answer (capped at 300 chars), citations array, and domain_cited boolean
echo "$BODY" | jq --arg domain "$DOMAIN" '{
  answer: (.choices[0].message.content[:300]),
  citations: (.citations // []),
  domain_cited: ((.citations // []) | any(test($domain)))
}'
