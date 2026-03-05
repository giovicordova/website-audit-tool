---
phase: 3
slug: fast-crawl
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-05
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash test scripts (same as Phase 1/2) |
| **Config file** | None |
| **Quick run command** | `bash tests/test-scoring.sh` |
| **Full suite command** | `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/test-scoring.sh`
- **After every plan wave:** Run `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | CRAW-02 | inspection | `grep -q "template type" .claude/skills/website-audit/SKILL.md` | SKILL.md exists | pending |
| 03-01-02 | 01 | 1 | CRAW-04 | inspection | `grep -q "Which pages should I audit" .claude/skills/website-audit/SKILL.md` | SKILL.md exists | pending |
| 03-01-03 | 01 | 1 | CRAW-03 | inspection | `grep -q "navigate_page" .claude/skills/website-audit/SKILL.md` | SKILL.md exists | pending |
| 03-01-04 | 01 | 1 | CRAW-01 | manual-only | Time a real audit run | N/A | pending |
| REGRESSION | - | - | SCOR-* | unit | `bash tests/test-scoring.sh` | Yes | pending |
| REGRESSION | - | - | PERF-* | unit | `bash tests/test-lighthouse-output.sh` | Yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test scripts or frameworks needed. This phase modifies SKILL.md instructions only — existing regression tests cover scoring/lighthouse.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Audit completes in under 1 minute | CRAW-01 | Depends on network, Lighthouse, chrome-devtools-mcp — no synthetic test possible | Run a full audit on a real site and time it end-to-end |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
