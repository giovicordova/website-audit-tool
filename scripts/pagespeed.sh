#!/bin/bash
# Usage: pagespeed.sh <url>
# Requires: PAGESPEED_API_KEY env var
# Returns: JSON with Core Web Vitals and Lighthouse scores

URL="$1"
API_KEY="${PAGESPEED_API_KEY}"

if [ -z "$URL" ]; then
  echo "Usage: pagespeed.sh <url>" >&2
  exit 1
fi

if [ -z "$API_KEY" ]; then
  echo "Error: PAGESPEED_API_KEY environment variable not set" >&2
  exit 1
fi

curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=${URL}&key=${API_KEY}&category=PERFORMANCE&category=ACCESSIBILITY&category=BEST_PRACTICES&category=SEO&strategy=mobile" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)

# Lighthouse scores
cats = data.get('lighthouseResult', {}).get('categories', {})
scores = {k: int(v.get('score', 0) * 100) for k, v in cats.items()}

# Core Web Vitals from field data (CrUX)
field = data.get('loadingExperience', {}).get('metrics', {})
vitals = {}
for metric, info in field.items():
    vitals[metric] = {
        'percentile': info.get('percentile'),
        'category': info.get('category')
    }

result = {'lighthouse_scores': scores, 'core_web_vitals': vitals}
print(json.dumps(result, indent=2))
"
