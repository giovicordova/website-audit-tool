---
phase: 4
slug: feature-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test scripts (no formal framework) |
| **Config file** | none |
| **Quick run command** | `bash tests/test-scoring.sh` |
| **Full suite command** | `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/test-scoring.sh`
- **After every plan wave:** Run `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 0 | AICR-01, AICR-02 | unit | `bash tests/test-ai-crawler-grading.sh` | No — W0 | pending |
| 04-01-02 | 01 | 0 | RULE-01 | unit | `bash tests/test-staleness-check.sh` | No — W0 | pending |
| 04-01-03 | 01 | 1 | AICR-01 | manual | Manual audit run | N/A | pending |
| 04-01-04 | 01 | 1 | AICR-02 | manual | Manual audit run | N/A | pending |
| 04-01-05 | 01 | 1 | AICR-03 | manual | Manual audit run | N/A | pending |
| 04-01-06 | 01 | 1 | RULE-01, RULE-02 | manual | Manual audit run | N/A | pending |
| 04-01-07 | 01 | 1 | COMP-01, COMP-02 | manual | Manual compare run | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `tests/test-ai-crawler-grading.sh` — tests robots.txt parsing against sample inputs (covers AICR-01, AICR-02)
- [ ] `tests/test-staleness-check.sh` — tests date comparison logic (covers RULE-01)
- [ ] `tests/fixtures/robots-full.txt` — sample robots.txt with comprehensive AI bot rules
- [ ] `tests/fixtures/robots-partial.txt` — sample robots.txt with partial AI bot rules
- [ ] `tests/fixtures/robots-none.txt` — sample robots.txt with no AI bot rules

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AI crawler recommendation text is actionable | AICR-03 | Natural language output from Claude | Run full audit, verify recommendation section exists and suggests specific robots.txt changes |
| Staleness warning appears at audit start | RULE-02 | Claude behavior during audit flow | Temporarily set a reference file date >90 days old, run audit, verify warning appears before results |
| Compare output has table + analysis only | COMP-01 | Claude output format | Run compare mode on 2 sites, verify output contains table and analysis but no full category reports |
| Compare output omits full category reports | COMP-02 | Claude output format | Same as COMP-01, verify no individual site audit sections appear |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
