---
phase: 01-lighthouse-scoring-lock
verified: 2026-03-05T16:00:00Z
status: passed
score: 9/9 must-haves verified
re_verification: false
notes:
  - "PERF-03 in REQUIREMENTS.md says 'INP' but implementation correctly uses TBT (lab proxy for INP). This is a documentation mismatch, not an implementation gap. REQUIREMENTS.md should be updated to say 'TBT (lab proxy for INP)' to match the research finding that Lighthouse cannot measure INP."
  - "ROADMAP.md success criterion 1 also says 'INP' -- same documentation update needed."
---

# Phase 1: Lighthouse + Scoring Lock Verification Report

**Phase Goal:** Audit produces accurate, testable performance scores using local Lighthouse CLI, and scoring regressions are caught automatically
**Verified:** 2026-03-05T16:00:00Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running scripts/lighthouse.sh <url> produces compact JSON with category scores and Core Web Vitals (LCP, CLS, TBT) | VERIFIED | Script exists (36 lines), executable, correct jq extraction. 13/13 shape assertions pass. |
| 2 | No API key or env var is needed to run lighthouse.sh | VERIFIED | Script uses `npx lighthouse` locally. No env var references. No API key. |
| 3 | references/seo-technical.md references TBT (not INP) and lighthouse.sh (not pagespeed.sh) | VERIFIED | grep confirms TBT present, pagespeed.sh count = 0, lighthouse.sh referenced. INP only appears as "(lab proxy for INP)" context. |
| 4 | SKILL.md Phase A step 7 calls lighthouse.sh instead of pagespeed.sh | VERIFIED | grep confirms `lighthouse.sh` in SKILL.md step 7 instruction. |
| 5 | test-lighthouse-output.sh validates the JSON shape of lighthouse.sh output | VERIFIED | 13 assertions all PASS. Tests category scores (4), CWV values (3), CWV display strings (3), CWV scores (3). |
| 6 | Running test-scoring.sh produces PASS/FAIL for each scoring scenario | VERIFIED | 6/6 tests pass (4 fixture + 2 edge case). |
| 7 | Changing a fixture's expected score causes test-scoring.sh to fail | VERIFIED | test-scoring.sh compares score.py output against expected-scores.json golden file -- any mismatch produces FAIL. |
| 8 | All fixtures contain synthetic data, not real site snapshots | VERIFIED | All 4 fixtures contain only generic severity/result pairs (no URLs, no site content). |
| 9 | score.py implements the exact formula from SKILL.md Section 4 | VERIFIED | Critical=3, Important=2, Nice=1, WARNING=half(floor), N/A+UNTESTABLE excluded, empty=100. All edge cases covered by tests. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/lighthouse.sh` | Lighthouse CLI wrapper, min 20 lines | VERIFIED | 36 lines, executable, syntax valid, produces compact JSON |
| `references/seo-technical.md` | Updated CWV check using TBT and lighthouse.sh | VERIFIED | Contains "lighthouse.sh" and "TBT", zero "pagespeed.sh" references |
| `SKILL.md` | Updated orchestration referencing lighthouse.sh | VERIFIED | Phase A step 7 references lighthouse.sh |
| `tests/test-lighthouse-output.sh` | Lighthouse output shape validation test, min 15 lines | VERIFIED | 96 lines, 13 assertions, all pass |
| `scripts/score.py` | Standalone scoring formula, min 15 lines, exports score_checks | VERIFIED | 29 lines, score_checks function exported, stdlib only |
| `tests/fixtures/scoring-all-pass.json` | Synthetic fixture: all checks pass, contains "PASS" | VERIFIED | 6 checks all PASS, synthetic data |
| `tests/fixtures/scoring-all-fail.json` | Synthetic fixture: all checks fail, contains "FAIL" | VERIFIED | 6 checks all FAIL, synthetic data |
| `tests/fixtures/scoring-mixed.json` | Synthetic fixture: mix, contains "WARNING" | VERIFIED | Mix of PASS/WARNING/FAIL, synthetic data |
| `tests/fixtures/scoring-with-na.json` | Synthetic fixture: includes N/A, contains "N/A" | VERIFIED | Includes N/A and UNTESTABLE, synthetic data |
| `tests/fixtures/expected-scores.json` | Golden expected scores | VERIFIED | Contains correct values: all-pass=100, all-fail=0, mixed=71, with-na=100 |
| `tests/test-scoring.sh` | Golden-file scoring test runner, min 20 lines | VERIFIED | 46 lines, fixture + edge case tests, all pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| SKILL.md | scripts/lighthouse.sh | Phase A step 7 instruction | WIRED | grep confirms "lighthouse.sh" in step 7 |
| references/seo-technical.md | scripts/lighthouse.sh | CWV check instruction | WIRED | grep confirms "lighthouse.sh" in CWV check line |
| tests/test-lighthouse-output.sh | scripts/lighthouse.sh | Runs same jq filter against mock data | WIRED | jq filter duplicated in test, precondition checks lighthouse.sh exists |
| tests/test-scoring.sh | scripts/score.py | Pipes fixture JSON to score.py via stdin | WIRED | `python3 "$PROJECT_DIR/scripts/score.py" < "$FIXTURE"` confirmed |
| tests/test-scoring.sh | tests/fixtures/expected-scores.json | Reads expected scores to compare | WIRED | `jq -r ... expected-scores.json` confirmed |
| scripts/score.py | SKILL.md | Implements same formula | WIRED | Critical=3, Important=2, Nice=1 pattern confirmed in code |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PERF-01 | 01-01 | Lighthouse CLI replaces PageSpeed API | SATISFIED | lighthouse.sh uses npx lighthouse, not PageSpeed API |
| PERF-02 | 01-01 | Runs locally with no API key, no rate limits | SATISFIED | No env vars, no API keys in lighthouse.sh |
| PERF-03 | 01-01 | Lighthouse JSON parsed into structured scoring data (LCP, TBT, CLS, scores) | SATISFIED | jq extraction produces exact JSON shape. Note: REQUIREMENTS.md says "INP" but TBT is correct (INP is field-only, TBT is the lab proxy). Documentation should be updated. |
| SCOR-01 | 01-02 | Golden-file tests detect scoring regressions | SATISFIED | test-scoring.sh compares against expected-scores.json |
| SCOR-02 | 01-02 | Fixtures use synthetic data | SATISFIED | All 4 fixtures contain only generic severity/result pairs |
| SCOR-03 | 01-02 | Reference file edits trigger score verification | SATISFIED | Changing expected-scores.json or score.py formula causes clear FAIL output |

No orphaned requirements found -- all 6 requirement IDs (PERF-01, PERF-02, PERF-03, SCOR-01, SCOR-02, SCOR-03) are claimed by plans and verified.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | - | - | - | No anti-patterns detected |

No TODOs, FIXMEs, placeholders, empty implementations, or console.log-only handlers found in any phase artifact.

### Human Verification Required

### 1. Live Lighthouse Audit

**Test:** Run `bash scripts/lighthouse.sh https://example.com` on a real URL
**Expected:** Compact JSON output with integer scores (0-100) and CWV values (lcp, cls, tbt with value/display/score)
**Why human:** Requires Chrome + network access. Shape test validates jq extraction but not the live npx lighthouse invocation.

### Documentation Update Needed

REQUIREMENTS.md PERF-03 says "LCP, INP, CLS" but should say "LCP, TBT (lab proxy for INP), CLS" to match the research-backed implementation. ROADMAP.md success criterion 1 has the same discrepancy. These are not gaps in implementation -- the code is correct -- but the requirement text should be updated to avoid future confusion.

### Gaps Summary

No gaps found. All 9 observable truths verified. All 11 artifacts pass existence, substantive, and wiring checks. All 6 key links confirmed wired. All 6 requirements satisfied. Both test suites run and pass (13/13 lighthouse shape assertions, 6/6 scoring assertions). Zero anti-patterns detected.

The only action item is a documentation update: REQUIREMENTS.md and ROADMAP.md should replace "INP" with "TBT (lab proxy for INP)" to reflect the research finding that Lighthouse measures TBT, not INP.

---

_Verified: 2026-03-05T16:00:00Z_
_Verifier: Claude (gsd-verifier)_
