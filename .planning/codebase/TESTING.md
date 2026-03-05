# Testing Patterns

**Analysis Date:** 2026-03-05

## Test Framework

**Runner:** None

There is no automated test framework, no test runner, no test files, and no CI pipeline. This project is a Claude Code Skill, not a traditional application. There are no `.test.*`, `.spec.*`, `test_*`, or `*_test.*` files anywhere in the repository.

## Current Validation Approach

Testing is done **manually through live audit runs**. The feedback loop is:

1. Run `audit {domain}` in Claude Code
2. Review the generated report in `docs/w-audit/audit-{domain}-{date}.md`
3. Review the audit log in `docs/logs/audit-log-{domain}-{date}.md`
4. The audit log's "Skill Performance Notes" section captures what worked, what failed, and what needs improving
5. Update `SKILL.md` or `references/*.md` based on findings

**Existing audit runs (used as regression baselines):**
- `docs/w-audit/audit-giovannicordova.com-2026-03-05.md` — 7 pages, grade A- (85/100)
- `docs/w-audit/audit-chapterpass.com-2026-03-05.md` — 7 pages, grade A- (89/100)

## What Could Be Tested

If automated testing were added, these are the testable components:

### Shell Scripts

**`scripts/pagespeed.sh`:**
- Input validation: missing URL argument exits with code 1
- Input validation: missing PAGESPEED_API_KEY env var exits with code 1
- Output: valid JSON with `lighthouse_scores` and `core_web_vitals` keys
- Could test with: `bats` (Bash Automated Testing System) or simple shell assertions

**`.claude/hooks/session-snapshot.sh`:**
- First run: creates snapshot file at `.claude/session-logs/audit-snapshot.txt`
- Subsequent runs: exits immediately without modifying snapshot
- Snapshot format: `filepath:epoch_mtime` pairs, sorted

**`.claude/hooks/stop-summary.sh`:**
- No changed files: outputs `{"decision": "approve"}`
- Changed files detected: outputs `{"decision": "block"}` with audit log template
- Second pass (`stop_hook_active=true`): cleans up snapshot and approves
- Input: reads JSON from stdin (expects `stop_hook_active` field)

### JavaScript Extraction Function

**`SKILL.md` lines 68-174 (browser_evaluate snippet):**
- Returns object with all expected keys (url, title, metaDescription, jsonLd, headings, images, etc.)
- Handles missing elements gracefully (null values, empty arrays)
- JSON-LD parsing survives malformed JSON blocks
- Could test with: jsdom or Playwright in a test harness against fixture HTML pages

### Scoring Logic

**Scoring rules in `SKILL.md` lines 196-218:**
- Critical = 3 points, Important = 2 points, Nice to Have = 1 point
- N/A checks excluded from denominator
- UNTESTABLE checks excluded from denominator
- Weighted average: AEO 25%, GEO 25%, SEO Technical 20%, SEO On-Page 15%, Structured Data 15%
- Letter grade thresholds: A+ (95+) through F (<50)
- Could test with: unit tests against known check results to verify scoring math

### Reference File Structure

**`references/*.md` (5 files):**
- Each file has `## Source`, `Last reviewed:`, and `## Checks` sections
- Checks organized under `### CRITICAL`, `### IMPORTANT`, `### NICE TO HAVE`
- Each check is a `- [ ]` checkbox item
- CONDITIONAL checks include explicit N/A instructions
- Could validate with: a markdown linter or custom parser that enforces structure

## Coverage

**Requirements:** None enforced. No coverage tooling exists.

**Effective coverage through manual runs:**
- The two completed audits exercise the full audit flow end-to-end
- SEO Technical category achieved 100/100 on giovannicordova.com, confirming all checks in that category ran correctly
- PageSpeed API path tested in "untestable" mode (API key not configured)
- Blog post crawl path tested (Phase D of audit flow)
- Compare mode defined in SKILL.md but no comparison report exists in `docs/w-audit/`, suggesting it has not been tested yet

## Test Gaps

**Compare mode (`compare site-a.com site-b.com`):**
- Defined in `SKILL.md` lines 286-304
- No comparison report found in `docs/w-audit/`
- Untested flow: side-by-side scoring, proportional weighting, comparison table generation

**Fix mode:**
- Described in `PROJECT-BRIEF.md` (Phase 3) but not implemented in `SKILL.md`
- No code exists for this feature yet

**PageSpeed API success path:**
- Both existing audits ran without a configured API key
- Core Web Vitals checks always marked UNTESTABLE
- The happy path (API returns data, scores calculated) is untested

**Edge cases in JS extraction:**
- Pages with no `<body>` text
- Pages with malformed JSON-LD (partially tested via try/catch)
- Pages with hundreds of images or links (performance)
- Non-English content
- SPAs with dynamic content loading

**Hook edge cases:**
- `stop-summary.sh` with multiple changed audit files (only processes first one via `head -1`)
- Snapshot file corruption or unexpected format
- Race conditions if multiple Claude sessions run simultaneously

## Recommendations for Adding Tests

If testing is desired, the recommended approach:

1. **Shell script tests with bats:** Install `bats-core`, write tests for `pagespeed.sh` and both hook scripts. Lowest effort, highest value for the existing codebase.

2. **Scoring unit tests:** Extract scoring logic into a standalone script or Python function, write tests with known inputs and expected outputs.

3. **JS extraction tests with Playwright:** Create fixture HTML pages, run the extraction function against them, assert expected output shape and values.

4. **Reference file linter:** A simple script that validates all 5 reference files follow the expected markdown structure.

---

*Testing analysis: 2026-03-05*
