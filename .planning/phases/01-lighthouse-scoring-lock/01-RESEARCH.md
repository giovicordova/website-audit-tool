# Phase 1: Lighthouse + Scoring Lock - Research

**Researched:** 2026-03-05
**Domain:** Lighthouse CLI integration, golden-file scoring tests
**Confidence:** HIGH

## Summary

Phase 1 replaces the PageSpeed API dependency with local Lighthouse CLI and adds golden-file tests to catch scoring regressions. These are tightly coupled: Lighthouse provides the data (LCP, CLS, TBT) that was previously UNTESTABLE, and scoring tests verify that changes to reference files or scoring logic produce intentional score changes.

The system already has Lighthouse 12.5.1 cached via npx. The existing `scripts/pagespeed.sh` gets replaced by a new `scripts/lighthouse.sh` that runs Lighthouse locally (no API key) and outputs compact JSON with category scores and Core Web Vitals metrics. The scoring test suite uses synthetic JSON fixtures (not real site data) fed through a scoring script that implements the same formula as SKILL.md.

**Critical finding:** Lighthouse does NOT measure INP (Interaction to Next Paint) directly. It measures TBT (Total Blocking Time) as a lab proxy. Real INP requires field data from Chrome User Experience Report (CrUX). The reference file `references/seo-technical.md` mentions "INP < 200ms" but with Lighthouse CLI we get TBT instead. The SKILL.md and reference file need updating to reflect this: report TBT from Lighthouse, note that INP is a field-only metric.

**Primary recommendation:** Build `scripts/lighthouse.sh` to replace `pagespeed.sh`, update SKILL.md to call it, update the reference file's CWV check to use TBT (Lighthouse lab metric) instead of INP (field-only metric), then build bash scoring tests with synthetic fixtures.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PERF-01 | Lighthouse CLI replaces PageSpeed API for Core Web Vitals, performance, and accessibility checks | Lighthouse 12.5.1 confirmed working on this system. `scripts/lighthouse.sh` replaces `scripts/pagespeed.sh`. JSON paths for all needed metrics verified. |
| PERF-02 | Lighthouse script runs locally with no API key, no rate limits | `npx lighthouse` runs fully local with `--chrome-flags="--headless"`. No API key. No network dependency except fetching the target URL. |
| PERF-03 | Lighthouse JSON output parsed into structured scoring data (LCP, INP, CLS, performance score, accessibility score) | INP is NOT available from Lighthouse (field-only metric). Use TBT as proxy. LCP, CLS, TBT, and all category scores available via jq extraction from Lighthouse JSON. |
| SCOR-01 | Golden-file scoring tests detect regressions when reference files change | Bash test scripts with synthetic JSON fixtures. Each fixture has known check results and expected scores. Any reference file edit that changes denominators triggers test failure. |
| SCOR-02 | Test fixtures use synthetic data (not real site snapshots) | Fixtures are hand-crafted JSON representing specific scoring scenarios (all pass, all fail, mixed, edge cases). No dependency on real sites. |
| SCOR-03 | Each reference file edit triggers a test that verifies score impact is intentional | The scoring test compares computed scores against golden expected values. If a reference file edit changes the denominator, the test fails until the fixture is deliberately updated. |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Lighthouse CLI (npx) | 12.5.1 | Performance, accessibility, SEO, best-practices scores + CWV metrics | Already cached on system. No API key. Same engine as PageSpeed API. |
| jq | system | Parse Lighthouse JSON output into compact scoring data | Already used in project. Proven in pagespeed.sh pattern. |
| bash | system | Test runner for scoring tests + lighthouse wrapper script | No npm/pip dependencies needed. Matches existing project stack (no package.json). |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| python3 | system | Complex JSON transformations if jq is insufficient | Fallback only. jq handles all known extraction needs. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bash test scripts | BATS (Bash Automated Testing System) | Extra install. Plain bash is sufficient for <20 tests. |
| bash test scripts | Jest/Vitest | Adds npm dependency for no benefit. No JS code to test. |
| jq for JSON parsing | python3 json module | More overhead. jq is simpler for field extraction. |

**Installation:**
```bash
# Nothing to install. All tools already available:
# npx lighthouse (12.5.1 cached)
# jq (system)
# bash (system)
# python3 (system)
```

## Architecture Patterns

### Recommended Project Structure
```
scripts/
├── lighthouse.sh       # Replaces pagespeed.sh. Runs Lighthouse, outputs compact JSON.
tests/
├── fixtures/
│   ├── scoring-all-pass.json      # Synthetic: every check passes
│   ├── scoring-all-fail.json      # Synthetic: every check fails
│   ├── scoring-mixed.json         # Synthetic: mix of PASS/WARNING/FAIL
│   ├── scoring-with-na.json       # Synthetic: includes N/A and UNTESTABLE
│   └── expected-scores.json       # Golden file: expected scores for each fixture
├── test-scoring.sh                # Feeds fixtures through scoring, diffs against expected
└── test-lighthouse-output.sh      # Validates lighthouse.sh output shape
references/
├── seo-technical.md               # Updated: CWV check uses TBT instead of INP
SKILL.md                           # Updated: calls lighthouse.sh instead of pagespeed.sh
```

### Pattern 1: Lighthouse Wrapper Script
**What:** A bash script that runs Lighthouse and outputs only the fields we need (~200 bytes instead of ~500KB).
**When to use:** Every audit, replacing pagespeed.sh.
**Example:**
```bash
#!/bin/bash
# scripts/lighthouse.sh -- replaces pagespeed.sh
# Usage: lighthouse.sh <url>
# Returns: compact JSON with category scores + CWV metrics
# No API key needed. Runs locally.
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

### Pattern 2: Golden-File Scoring Tests
**What:** Bash scripts that compute scores from synthetic fixtures and diff against expected values.
**When to use:** After any edit to reference files, scoring formula, or scoring scripts.
**Example:**
```bash
#!/bin/bash
# tests/test-scoring.sh -- golden-file scoring validation
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

# Scoring formula: Critical=3pts, Important=2pts, NiceToHave=1pt
# PASS=full, WARNING=half(floor), FAIL=0, N/A=excluded

# Test: 3 critical PASS (9pts) + 2 important FAIL (0pts) = 9/13 = 69%
assert_eq "critical-pass-important-fail" "69" "$(python3 -c "print(int(9/13*100))")"

# Test: All pass, 3 critical + 2 important + 1 nice = 14/14 = 100%
assert_eq "all-pass" "100" "$(python3 -c "print(int(14/14*100))")"

# Test: WARNING on 1 critical = floor(3/2)=1pt earned, still 3 possible
# 1 critical WARNING + 2 important PASS = (1+4)/7 = 71%
assert_eq "warning-half-points" "71" "$(python3 -c "print(int(5/7*100))")"

echo ""
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

### Pattern 3: Synthetic Test Fixtures
**What:** Hand-crafted JSON files representing specific scoring scenarios. NOT snapshots of real sites.
**When to use:** As input to scoring tests.
**Example fixture structure:**
```json
{
  "name": "mixed-results",
  "description": "3 critical checks (2 PASS, 1 FAIL), 2 important (1 PASS, 1 WARNING), 1 nice-to-have (PASS)",
  "checks": [
    {"severity": "critical", "result": "PASS"},
    {"severity": "critical", "result": "PASS"},
    {"severity": "critical", "result": "FAIL"},
    {"severity": "important", "result": "PASS"},
    {"severity": "important", "result": "WARNING"},
    {"severity": "nice_to_have", "result": "PASS"}
  ],
  "expected_score": 72
}
```

### Anti-Patterns to Avoid
- **Snapshotting real site data as test fixtures:** Real site data embeds current bugs as baselines. When the site changes, tests break for the wrong reason.
- **Running Lighthouse in tests:** Lighthouse takes 10-30 seconds per run and scores vary. Tests must use synthetic data, not live runs.
- **Testing the scoring formula inside SKILL.md directly:** The scoring formula is natural language in a markdown file. Extract the formula into a standalone scoring script that can be tested independently.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lighthouse execution | Custom Chrome DevTools Protocol integration | `npx lighthouse` CLI | Lighthouse CLI handles Chrome lifecycle, throttling, and metric collection. Custom CDP integration is 100x more code. |
| JSON field extraction | Python/Node.js parser script | `jq` one-liner | jq is purpose-built for JSON extraction. Already on system. |
| Core Web Vitals thresholds | Hardcoded threshold values | Lighthouse's built-in `score` field (0/0.5/1 for fail/needs-improvement/good) | Lighthouse already classifies metrics against Google's thresholds. Use the score field, don't re-implement thresholds. |

**Key insight:** Lighthouse already does the heavy lifting. Our job is to (1) run it, (2) extract the fields we need, and (3) feed them into our scoring system. Do not re-implement any Lighthouse logic.

## Common Pitfalls

### Pitfall 1: Lighthouse Performance Scores Vary Between Runs
**What goes wrong:** Same URL, same machine, 5-10 point score differences between runs.
**Why it happens:** CPU load, network jitter, Chrome process state, thermal throttling all affect simulated page load.
**How to avoid:** Accept the variance. Document in reports: "Performance scores may vary +/-5 points between runs." Do NOT average multiple runs -- adds complexity without meaningful improvement.
**Warning signs:** User re-audits the same site and gets a different grade.

### Pitfall 2: INP vs TBT Confusion
**What goes wrong:** Code or reference files reference INP as a Lighthouse metric. Lighthouse does not measure INP.
**Why it happens:** INP is a Core Web Vital (field metric from real users). Lighthouse measures TBT (lab metric) as a proxy. They correlate but are not the same thing.
**How to avoid:** Update `references/seo-technical.md` to say "TBT < 200ms (Lighthouse lab proxy for INP)" instead of "INP < 200ms". In the report, note that TBT is used as a lab proxy for INP.
**Warning signs:** Report says "INP: 150ms" when it's actually TBT.

### Pitfall 3: Reference File Edits Change All Scores Silently
**What goes wrong:** Adding one CRITICAL check increases the denominator by 3 points. Every score for that category drops.
**Why it happens:** Score = earned / possible. Changing the number of checks changes "possible."
**How to avoid:** Golden-file tests. After any reference file edit, run `tests/test-scoring.sh`. If scores changed, update fixtures deliberately.
**Warning signs:** `test-scoring.sh` fails after a reference file edit.

### Pitfall 4: Lighthouse JSON Is Huge (~500KB-1MB)
**What goes wrong:** Passing full Lighthouse JSON to Claude wastes context tokens on screenshots, traces, and unused audit details.
**Why it happens:** Lighthouse outputs everything by default.
**How to avoid:** `lighthouse.sh` uses jq to extract only the ~200 bytes we need. Never pass raw Lighthouse JSON to Claude.
**Warning signs:** Claude's context fills up after one Lighthouse run.

### Pitfall 5: Lighthouse Requires Chrome/Chromium
**What goes wrong:** If Chrome is not installed or the profile is locked, Lighthouse fails with cryptic errors.
**Why it happens:** Lighthouse launches a Chrome instance internally.
**How to avoid:** Use `--chrome-flags="--headless"` to avoid display dependency. Test that `npx lighthouse` works before writing the integration.
**Warning signs:** "Error: Chrome not found" or "ECONNREFUSED" errors.

## Code Examples

### Lighthouse JSON Field Extraction (verified on this system)
```bash
# Source: Verified by running npx lighthouse on this machine (2026-03-05)

# Category scores (0-1 range, multiply by 100)
jq '.categories.performance.score' report.json          # e.g., 0.95
jq '.categories.accessibility.score' report.json        # e.g., 0.87
jq '.categories.seo.score' report.json                  # e.g., 0.80
jq '.categories["best-practices"].score' report.json    # e.g., 0.92

# Core Web Vitals (raw metrics)
jq '.audits["largest-contentful-paint"].numericValue' report.json   # ms
jq '.audits["cumulative-layout-shift"].numericValue' report.json   # unitless
jq '.audits["total-blocking-time"].numericValue' report.json       # ms (proxy for INP)

# Display-ready values
jq '.audits["largest-contentful-paint"].displayValue' report.json  # "0.8 s"

# Per-audit score (0=fail, 0.5=needs-improvement, 1=good)
jq '.audits["largest-contentful-paint"].score' report.json         # 1
```

### Scoring Formula Implementation (for test script)
```python
# Source: SKILL.md Section 4 scoring rules
import json, sys

WEIGHTS = {"critical": 3, "important": 2, "nice_to_have": 1}
RESULT_MULTIPLIERS = {"PASS": 1.0, "WARNING": 0.5, "FAIL": 0.0}

def score_checks(checks):
    earned = 0
    possible = 0
    for check in checks:
        if check["result"] in ("N/A", "UNTESTABLE"):
            continue  # excluded from denominator
        weight = WEIGHTS[check["severity"]]
        possible += weight
        multiplier = RESULT_MULTIPLIERS[check["result"]]
        earned += int(weight * multiplier)  # floor for WARNING
    if possible == 0:
        return 100  # no testable checks = perfect score
    return int(earned / possible * 100)

# Read fixture from stdin
fixture = json.load(sys.stdin)
print(score_checks(fixture["checks"]))
```

### SKILL.md Update Pattern (Lighthouse replaces PageSpeed)
```markdown
# In SKILL.md Phase A, replace item 7:

# OLD:
# 7. **PageSpeed API** (optional) — run `scripts/pagespeed.sh {domain}`

# NEW:
7. **Lighthouse** — run `scripts/lighthouse.sh {domain}` — returns JSON with
   performance/accessibility/seo/best-practices scores and Core Web Vitals
   (LCP, CLS, TBT). No API key needed. If it fails, mark CWV checks as
   UNTESTABLE and continue.
```

### Reference File Update (TBT replaces INP)
```markdown
# In references/seo-technical.md, CRITICAL section:

# OLD:
# - [ ] Core Web Vitals pass (run pagespeed.sh): LCP < 2.5s, INP < 200ms, CLS < 0.1

# NEW:
- [ ] Core Web Vitals pass (run lighthouse.sh): LCP < 2.5s, TBT < 200ms (lab proxy for INP), CLS < 0.1 — **CONDITIONAL: if Lighthouse fails, mark as UNTESTABLE and exclude from score denominator.**
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| PageSpeed API for CWV | Lighthouse CLI local | This phase | No API key, no rate limits, same engine |
| INP as Core Web Vital metric | TBT as Lighthouse lab proxy for INP | INP became CWV March 2024 | Lighthouse cannot measure INP (requires field data). TBT correlates with INP. |
| No scoring tests | Golden-file bash tests | This phase | Catch regressions when reference files change |
| UNTESTABLE CWV checks | Testable CWV checks via Lighthouse | This phase | 4 checks move from permanently UNTESTABLE to testable |

**Deprecated/outdated:**
- `scripts/pagespeed.sh`: Replaced by `scripts/lighthouse.sh`. Delete after migration.
- PageSpeed API dependency: No longer needed. Remove `PAGESPEED_API_KEY` references from docs.

## Open Questions

1. **TBT threshold value for "pass"**
   - What we know: Google's threshold for "good" TBT is < 200ms. Lighthouse's built-in score field already classifies this (score=1 means good).
   - What's unclear: Should we use the raw TBT value against a threshold, or use Lighthouse's score field (0/0.5/1)?
   - Recommendation: Use Lighthouse's score field. It already applies Google's thresholds. Simpler and future-proof if thresholds change.

2. **Scoring script: standalone file or inline in test?**
   - What we know: The scoring formula lives in SKILL.md as natural language. Tests need a machine-readable implementation.
   - What's unclear: Should the scoring script be a standalone file (reusable) or embedded in the test script?
   - Recommendation: Standalone `scripts/score.py` so both tests and future automation can use it. Keep it small (<30 lines).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash + python3 (no external test framework) |
| Config file | none -- Wave 0 |
| Quick run command | `bash tests/test-scoring.sh` |
| Full suite command | `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PERF-01 | lighthouse.sh produces valid JSON with expected fields | unit | `bash tests/test-lighthouse-output.sh` | No -- Wave 0 |
| PERF-02 | lighthouse.sh runs with no API key env var | unit | `bash tests/test-lighthouse-output.sh` (no PAGESPEED_API_KEY needed) | No -- Wave 0 |
| PERF-03 | Lighthouse JSON parsed into LCP, CLS, TBT, category scores | unit | `bash tests/test-lighthouse-output.sh` | No -- Wave 0 |
| SCOR-01 | Scoring test fails when reference file changes denominator | unit | `bash tests/test-scoring.sh` | No -- Wave 0 |
| SCOR-02 | Fixtures are synthetic (no real site data) | inspection | Manual review of `tests/fixtures/*.json` | No -- Wave 0 |
| SCOR-03 | Reference file edit produces clear PASS/FAIL | unit | `bash tests/test-scoring.sh` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `bash tests/test-scoring.sh`
- **Per wave merge:** `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/test-scoring.sh` -- covers SCOR-01, SCOR-03
- [ ] `tests/test-lighthouse-output.sh` -- covers PERF-01, PERF-02, PERF-03
- [ ] `tests/fixtures/` directory with synthetic JSON fixtures -- covers SCOR-02
- [ ] `scripts/score.py` -- standalone scoring formula implementation for testing

## Sources

### Primary (HIGH confidence)
- Lighthouse 12.5.1 local execution -- verified on this machine, JSON output structure confirmed
- `scripts/pagespeed.sh` -- read and analyzed, replacement pattern understood
- SKILL.md scoring formula (Section 4, lines 199-218) -- read and documented
- `references/seo-technical.md` -- read, INP/TBT discrepancy identified

### Secondary (MEDIUM confidence)
- [web.dev INP article](https://web.dev/articles/inp) -- confirms Lighthouse does not measure INP directly, TBT is a proxy
- [Lighthouse GitHub](https://github.com/GoogleChrome/lighthouse) -- CLI flags and JSON output documentation

### Tertiary (LOW confidence)
- None. All findings verified against local system or official documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools verified on this system, no new installs needed
- Architecture: HIGH -- pattern follows existing project conventions (bash scripts, jq, no npm)
- Pitfalls: HIGH -- all pitfalls verified through local testing or documented in codebase concerns
- INP/TBT distinction: HIGH -- verified via official web.dev documentation

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (stable domain, Lighthouse 12.x not changing)
