---
phase: 01-lighthouse-scoring-lock
plan: 01
subsystem: testing
tags: [lighthouse, bash, jq, core-web-vitals, tbt]

# Dependency graph
requires: []
provides:
  - scripts/lighthouse.sh — local Lighthouse CLI wrapper producing compact JSON
  - tests/test-lighthouse-output.sh — shape validation test for lighthouse.sh jq extraction
  - Updated SKILL.md and seo-technical.md referencing lighthouse.sh and TBT
affects: [01-lighthouse-scoring-lock]

# Tech tracking
tech-stack:
  added: [npx lighthouse 12.x, jq]
  patterns: [bash wrapper script with jq extraction, mock-based shape testing]

key-files:
  created:
    - scripts/lighthouse.sh
    - tests/test-lighthouse-output.sh
  modified:
    - references/seo-technical.md
    - SKILL.md

key-decisions:
  - "TBT used as lab proxy for INP in all Lighthouse-based checks (INP is field-only)"
  - "jq filter duplicated in test to validate extraction logic independently of npx lighthouse"

patterns-established:
  - "Bash wrapper scripts: validate input, run tool, extract with jq, error to stderr"
  - "Shape tests: mock raw tool output, apply same jq filter, assert field values"

requirements-completed: [PERF-01, PERF-02, PERF-03]

# Metrics
duration: 3min
completed: 2026-03-05
---

# Phase 1 Plan 1: Lighthouse CLI Wrapper Summary

**Local Lighthouse CLI wrapper replacing PageSpeed API, with TBT instead of INP and 13-assertion shape test**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-05T15:35:59Z
- **Completed:** 2026-03-05T15:39:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created scripts/lighthouse.sh: runs Lighthouse locally via npx, outputs compact JSON (~200 bytes) with category scores and Core Web Vitals (LCP, CLS, TBT)
- Updated references/seo-technical.md: all CWV checks use TBT (not INP) and reference lighthouse.sh (not pagespeed.sh)
- Updated SKILL.md Phase A step 7: calls lighthouse.sh, no API key needed
- Created tests/test-lighthouse-output.sh: 13 assertions validating jq extraction against mock Lighthouse JSON

## Task Commits

Each task was committed atomically:

1. **Task 1: Create lighthouse.sh and update SKILL.md + reference file** - `50c14b6` (feat)
2. **Task 2: Create lighthouse output shape test** - `96c083f` (test)

## Files Created/Modified
- `scripts/lighthouse.sh` - Lighthouse CLI wrapper producing compact JSON with category scores + CWV
- `tests/test-lighthouse-output.sh` - Shape validation test (13 assertions, <1s runtime)
- `references/seo-technical.md` - CWV checks now use TBT and lighthouse.sh
- `SKILL.md` - Phase A step 7 calls lighthouse.sh instead of pagespeed.sh

## Decisions Made
- TBT used as lab proxy for INP -- Lighthouse does not measure INP directly (field-only metric from CrUX)
- jq filter duplicated between lighthouse.sh and test script to validate extraction logic independently without running a live audit

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed bash arithmetic with set -e**
- **Found during:** Task 2 (test script)
- **Issue:** `((PASS++))` returns exit code 1 when incrementing from 0 (falsy in bash), which kills the script under `set -e`
- **Fix:** Changed to `PASS=$((PASS + 1))` which always returns exit code 0
- **Files modified:** tests/test-lighthouse-output.sh
- **Verification:** All 13 assertions pass
- **Committed in:** 96c083f (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor bash idiom fix. No scope creep.

## Issues Encountered
None beyond the bash arithmetic fix documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- lighthouse.sh ready for use in audits (replaces pagespeed.sh)
- pagespeed.sh intentionally kept for now until migration confirmed working
- Golden-file scoring tests (SCOR-01 through SCOR-03) still needed in next plan

---
*Phase: 01-lighthouse-scoring-lock*
*Completed: 2026-03-05*
