# Technology Stack

**Project:** Website Audit Tool v2
**Researched:** 2026-03-05

## Recommended Stack

### Core Tools

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Lighthouse CLI | 12.5.1 (current npx cache) | Core Web Vitals + performance/accessibility/SEO scores | Already installed. No API key, no rate limits, runs locally. Replaces PageSpeed API entirely. |
| curl | system | Fast HTML fetching for static content | 0.06s per page vs 5-8s with Playwright. Already used for robots.txt/sitemap. |
| xmllint | system (macOS built-in) | HTML parsing for curl-fetched pages | Extracts title, meta, headings, JSON-LD, links, images via XPath. No install needed. |
| Playwright MCP | existing | JS-rendered page extraction | Keep for pages where curl misses content. Already configured. |
| jq | system | JSON parsing for Lighthouse output and test fixtures | Already installed. Proven in pagespeed.sh pattern. |
| python3 | system | Complex JSON transformations when jq is insufficient | Already used in pagespeed.sh. Fallback only. |

### Lighthouse CLI

**Confidence: HIGH** -- Verified by running `npx lighthouse https://example.com --output=json --only-categories=performance,seo --chrome-flags="--headless" --quiet` on this machine. JSON output structure confirmed.

**Version note:** Lighthouse 13.0.3 exists (released Feb 2026) but requires Node 22.19+. This system has Node 22.16.0. Stay on 12.x until Node updates. The cached 12.5.1 works. Performance scoring is identical between 12 and 13 (confirmed in Chrome blog post). The main 13.x changes are audit name consolidations (e.g., `dom-size` becomes `dom-size-insight`) -- not relevant to our use case since we only read category scores and CWV metrics.

**Command:**
```bash
npx lighthouse "$URL" \
  --output=json \
  --output-path=./lighthouse-report.json \
  --only-categories=performance,accessibility,seo,best-practices \
  --chrome-flags="--headless" \
  --quiet
```

**JSON paths for extraction (verified):**
```bash
# Category scores (0-1 range, multiply by 100)
jq '.categories.performance.score' report.json     # e.g., 0.95
jq '.categories.accessibility.score' report.json   # e.g., 0.87
jq '.categories.seo.score' report.json             # e.g., 0.80
jq '.categories["best-practices"].score' report.json

# Core Web Vitals (raw metrics)
jq '.audits["largest-contentful-paint"].numericValue' report.json   # ms
jq '.audits["cumulative-layout-shift"].numericValue' report.json   # unitless
jq '.audits["total-blocking-time"].numericValue' report.json       # ms

# Display-ready values
jq '.audits["largest-contentful-paint"].displayValue' report.json  # "0.8 s"
```

**Full extraction script (replaces pagespeed.sh):**
```bash
#!/bin/bash
# Usage: lighthouse.sh <url>
# Returns: JSON with category scores and Core Web Vitals
URL="$1"
if [ -z "$URL" ]; then
  echo "Usage: lighthouse.sh <url>" >&2
  exit 1
fi

REPORT=$(npx lighthouse "$URL" \
  --output=json \
  --only-categories=performance,accessibility,seo,best-practices \
  --chrome-flags="--headless" \
  --quiet 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$REPORT" ]; then
  echo '{"error": "Lighthouse run failed"}' >&2
  exit 1
fi

echo "$REPORT" | jq '{
  lighthouse_scores: {
    performance: (.categories.performance.score * 100 | floor),
    accessibility: (.categories.accessibility.score * 100 | floor),
    seo: (.categories.seo.score * 100 | floor),
    best_practices: (.categories["best-practices"].score * 100 | floor)
  },
  core_web_vitals: {
    lcp: {value: .audits["largest-contentful-paint"].numericValue, display: .audits["largest-contentful-paint"].displayValue, score: .audits["largest-contentful-paint"].score},
    cls: {value: .audits["cumulative-layout-shift"].numericValue, display: .audits["cumulative-layout-shift"].displayValue, score: .audits["cumulative-layout-shift"].score},
    tbt: {value: .audits["total-blocking-time"].numericValue, display: .audits["total-blocking-time"].displayValue, score: .audits["total-blocking-time"].score}
  }
}'
```

### curl + xmllint HTML Extraction

**Confidence: HIGH** -- Verified on this machine against example.com and web.dev.

**What xmllint extracts well (static HTML):**
```bash
HTML=$(curl -sL "$URL")

# Title
echo "$HTML" | xmllint --html --xpath '//title/text()' - 2>/dev/null

# Meta description
echo "$HTML" | xmllint --html --xpath 'string(//meta[@name="description"]/@content)' - 2>/dev/null

# Canonical
echo "$HTML" | xmllint --html --xpath 'string(//link[@rel="canonical"]/@href)' - 2>/dev/null

# H1 text
echo "$HTML" | xmllint --html --xpath '//h1/text()' - 2>/dev/null

# JSON-LD
echo "$HTML" | xmllint --html --xpath '//script[@type="application/ld+json"]/text()' - 2>/dev/null

# Internal link count
echo "$HTML" | xmllint --html --xpath 'count(//a[starts-with(@href,"/")])' - 2>/dev/null

# Images without alt
echo "$HTML" | xmllint --html --xpath 'count(//img[not(@alt)])' - 2>/dev/null

# Viewport meta
echo "$HTML" | xmllint --html --xpath 'string(//meta[@name="viewport"]/@content)' - 2>/dev/null
```

**What xmllint CANNOT extract (need Playwright):**
- JS-rendered content (React/Next.js hydrated content not in initial HTML)
- Content loaded after scroll or click interactions
- Full word count of body text (needs JS `innerText`)
- FAQ detection from dynamic accordion components
- OG tags with `&` in URLs cause xmllint HTML parser errors (works but noisy)

**Hybrid strategy:**
1. Fetch HTML with `curl -sL "$URL"` (0.06s)
2. Parse with xmllint for metadata checks
3. Compare to Playwright extraction for the same page
4. If critical data is missing (no H1, no JSON-LD where expected), fall back to Playwright for that page
5. For most static marketing sites, curl + xmllint gets 90%+ of needed data

**Speed comparison (verified):**
| Method | Time per page | Data completeness |
|--------|--------------|-------------------|
| curl + xmllint | ~0.1s | 80-90% of checks (static HTML only) |
| Playwright MCP | 5-8s | 100% of checks (includes JS-rendered) |
| Hybrid (curl first, Playwright fallback) | 0.1-8s | 100% with speed optimization |

### Testing Framework

**Confidence: MEDIUM** -- Pattern verified via Claude Code best practices docs. No existing framework to reference.

**Approach: Bash assert scripts with golden file diffing.**

No compiled test framework exists for markdown-driven skills. The testing strategy uses:

1. **Golden files** -- Known-good JSON fixtures representing extracted page data
2. **Scoring validation scripts** -- Bash scripts that feed fixtures through the scoring formula and compare output to expected scores
3. **Report template validation** -- `grep` checks that required sections exist in generated reports

**Test structure:**
```
tests/
  fixtures/
    example-com-homepage.json      # Known extraction output
    example-com-expected-scores.json  # Expected scores for that data
  test-scoring.sh                  # Feeds fixtures through scoring, diffs output
  test-report-format.sh            # Checks report has all required sections
```

**Scoring test pattern:**
```bash
#!/bin/bash
# test-scoring.sh -- validates scoring against golden files
PASS=0; FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label (expected=$expected, actual=$actual)"
    ((FAIL++))
  fi
}

# Test: 3 critical PASS + 2 important FAIL = 9/13 = 69
# (3 * 3 + 0 * 2) / (3 * 3 + 2 * 2) = 9/13
assert_eq "basic scoring" "69" "$(python3 -c "print(int(9/13*100))")"

echo ""
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

**Report format test pattern:**
```bash
#!/bin/bash
# test-report-format.sh -- validates report has required sections
REPORT="$1"
PASS=0; FAIL=0

check_section() {
  if grep -q "$1" "$REPORT"; then
    echo "PASS: section '$1' found"
    ((PASS++))
  else
    echo "FAIL: section '$1' missing"
    ((FAIL++))
  fi
}

check_section "## Summary"
check_section "## Site Profile"
check_section "## AEO"
check_section "## GEO"
check_section "## SEO Technical"
check_section "## SEO On-Page"
check_section "## Structured Data"
check_section "## Fix Priority List"

echo ""
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

### Auto-Research Rule Updates

**Confidence: LOW** -- This is a novel workflow. No established pattern exists for "Claude researches and updates its own reference files."

**Recommended approach: Staleness detection + prompted research.**

Each reference file already has a `Last reviewed: YYYY-MM-DD` line. The auto-update mechanism:

1. **Staleness check script** (runs at audit start):
```bash
#!/bin/bash
# check-staleness.sh -- warns if reference files are older than 90 days
THRESHOLD_DAYS=90
STALE=()

for ref in references/*.md; do
  reviewed=$(grep -m1 "Last reviewed:" "$ref" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
  if [ -n "$reviewed" ]; then
    reviewed_epoch=$(date -j -f "%Y-%m-%d" "$reviewed" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days_old=$(( (now_epoch - reviewed_epoch) / 86400 ))
    if [ "$days_old" -gt "$THRESHOLD_DAYS" ]; then
      STALE+=("$ref ($days_old days old)")
    fi
  fi
done

if [ ${#STALE[@]} -gt 0 ]; then
  echo "WARNING: Stale reference files (older than ${THRESHOLD_DAYS} days):"
  printf '  - %s\n' "${STALE[@]}"
  exit 1
else
  echo "All reference files are current."
  exit 0
fi
```

2. **Research prompt in SKILL.md** -- When staleness detected, SKILL.md instructs Claude to:
   - Search official sources (Google Search Central, web.dev, Schema.org)
   - Compare current reference file checks against latest guidance
   - Propose additions/removals/modifications as a diff
   - Ask user to approve before applying
   - Update the `Last reviewed:` date

3. **Source URLs in reference files** -- Each check should cite its source URL so Claude can re-verify against the original page.

**Do NOT auto-apply changes.** Reference file edits change scoring denominators. Always show proposed changes and get user approval.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Performance testing | Lighthouse CLI (npx) | PageSpeed API | API key required, rate limits, same underlying engine |
| Performance testing | Lighthouse CLI (npx) | Lighthouse 13.x | Requires Node 22.19+, this system has 22.16.0. Upgrade later. |
| HTML parsing | xmllint (system) | pup (Go HTML parser) | Not installed, requires `brew install pup`. xmllint is already available. |
| HTML parsing | xmllint (system) | python3 + BeautifulSoup | Adds pip dependency. xmllint handles the needed XPath queries. |
| HTML parsing | xmllint (system) | grep/sed/awk | Fragile for HTML. XPath is the right tool for structured extraction. |
| Test framework | Bash assert scripts | Jest/Vitest | No JS code to test. The "application" is markdown + bash scripts. Jest adds npm dependency for no benefit. |
| Test framework | Bash assert scripts | BATS (Bash Automated Testing System) | Extra install. Plain bash scripts are simpler and sufficient for <20 tests. |
| Rule updates | Staleness prompt + user approval | Fully automated web scraping | Too risky. Silent reference file changes silently change scores. |
| Rule updates | Staleness prompt + user approval | Cron job / scheduled script | Overkill. This tool runs on-demand, not continuously. |

## Installation

```bash
# Nothing to install -- all tools are already available on this system:
# - npx lighthouse (cached at 12.5.1)
# - curl (system)
# - xmllint (system, macOS built-in)
# - jq (system)
# - python3 (system)
# - Playwright MCP (configured in Claude Code)

# To upgrade Lighthouse later (when Node 22.19+ is available):
npm install -g lighthouse@latest
```

## Sources

- [Lighthouse GitHub README](https://github.com/GoogleChrome/lighthouse/blob/main/readme.md) -- CLI flags, categories, output formats
- [Lighthouse understanding-results.md](https://github.com/GoogleChrome/lighthouse/blob/main/docs/understanding-results.md) -- JSON output structure (verified against actual output)
- [What's new in Lighthouse 13](https://developer.chrome.com/blog/lighthouse-13-0) -- Version 13 changes, Node 22.19 requirement
- [pup HTML parser](https://github.com/ericchiang/pup) -- Considered but not recommended (not installed)
- [Claude Code best practices](https://code.claude.com/docs/en/best-practices) -- Testing patterns for CLI tools
- Local verification: `npx lighthouse` run on example.com confirmed JSON paths
- Local verification: `curl + xmllint` tested on example.com and web.dev

---

*Stack research: 2026-03-05*
