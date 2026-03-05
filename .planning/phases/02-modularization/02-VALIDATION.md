---
phase: 2
slug: modularization
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash test scripts (custom assert_eq) |
| **Config file** | None — tests are standalone bash scripts |
| **Quick run command** | `bash tests/test-scoring.sh` |
| **Full suite command** | `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/test-scoring.sh`
- **After every plan wave:** Run `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | MODU-01 | smoke | `test -f modules/extraction.js && echo PASS` | Will be created | pending |
| 2-01-02 | 01 | 1 | MODU-02 | smoke | `test -f modules/report-template.md && echo PASS` | Will be created | pending |
| 2-01-03 | 01 | 1 | MODU-03 | grep | `grep -q "Critical checks: 3 points" SKILL.md && echo PASS` | Yes | pending |
| 2-01-04 | 01 | 1 | MODU-04 | count | `[ $(wc -l < SKILL.md) -le 150 ] && echo PASS` | Yes | pending |
| 2-REG-01 | 01 | 1 | REGRESSION | unit | `bash tests/test-scoring.sh` | Yes | pending |
| 2-REG-02 | 01 | 1 | REGRESSION | unit | `bash tests/test-lighthouse-output.sh` | Yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test setup needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Report output identical after restructuring | MODU-02 | Report format is free-text markdown, not structured data | Audit same test URL before/after extraction, diff the reports |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
