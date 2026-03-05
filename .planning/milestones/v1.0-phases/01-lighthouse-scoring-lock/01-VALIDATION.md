---
phase: 1
slug: lighthouse-scoring-lock
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + python3 (no external test framework) |
| **Config file** | none — Wave 0 creates test files |
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
| 01-01-01 | 01 | 0 | SCOR-01, SCOR-03 | unit | `bash tests/test-scoring.sh` | No — W0 | pending |
| 01-01-02 | 01 | 0 | PERF-01, PERF-02, PERF-03 | unit | `bash tests/test-lighthouse-output.sh` | No — W0 | pending |
| 01-01-03 | 01 | 0 | SCOR-02 | inspection | Manual review of `tests/fixtures/*.json` | No — W0 | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] `tests/test-scoring.sh` — scoring golden-file tests for SCOR-01, SCOR-03
- [ ] `tests/test-lighthouse-output.sh` — lighthouse output shape validation for PERF-01, PERF-02, PERF-03
- [ ] `tests/fixtures/` — synthetic JSON fixtures for SCOR-02
- [ ] `scripts/score.py` — standalone scoring formula implementation

*All test infrastructure must be created in Wave 0.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fixtures contain no real site data | SCOR-02 | Requires human judgment on whether data is synthetic | Review each file in `tests/fixtures/` — verify JSON is hand-crafted with known values, not copied from a real Lighthouse run |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
