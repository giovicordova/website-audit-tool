# Roadmap: Website Audit Tool v2

## Overview

Evolve the existing monolithic audit skill into a modular, testable, fast system. The journey starts by replacing the broken performance pipeline (Lighthouse CLI), then locking down scoring with regression tests, restructuring the monolith into focused modules, speeding up crawling, and finally adding feature polish (AI crawler policy, stale rules, simplified compare). Each phase delivers a working improvement on its own.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Lighthouse + Scoring Lock** - Replace broken PageSpeed API with Lighthouse CLI and add golden-file scoring tests
- [ ] **Phase 2: Modularization** - Split SKILL.md monolith into focused modules with scoring tests as safety net
- [ ] **Phase 3: Fast Crawl** - Optimize crawl speed to under 1 minute with smart page selection and user control
- [ ] **Phase 4: Feature Polish** - AI crawler policy grading, stale rule detection, and simplified compare mode

## Phase Details

### Phase 1: Lighthouse + Scoring Lock
**Goal**: Audit produces accurate, testable performance scores using local Lighthouse CLI, and scoring regressions are caught automatically
**Depends on**: Nothing (first phase)
**Requirements**: PERF-01, PERF-02, PERF-03, SCOR-01, SCOR-02, SCOR-03
**Success Criteria** (what must be TRUE):
  1. Running an audit on any site produces Core Web Vitals scores (LCP, INP, CLS) and category scores (performance, accessibility) from Lighthouse -- no UNTESTABLE checks remain
  2. Lighthouse runs locally with zero API keys or external service dependencies
  3. Editing a reference file and running the scoring test suite produces a clear PASS/FAIL indicating whether scores changed
  4. Test fixtures use synthetic data, not snapshots of real sites
**Plans:** 2 plans

Plans:
- [ ] 01-01-PLAN.md — Lighthouse CLI wrapper + reference/SKILL.md updates + output shape test
- [ ] 01-02-PLAN.md — Scoring engine (score.py) + synthetic fixtures + golden-file test runner

### Phase 2: Modularization
**Goal**: SKILL.md is a short orchestrator that dispatches to focused module files, making edits safe and isolated
**Depends on**: Phase 1 (scoring tests provide safety net for restructuring)
**Requirements**: MODU-01, MODU-02, MODU-03, MODU-04
**Success Criteria** (what must be TRUE):
  1. SKILL.md is under 150 lines and contains only orchestration logic (parse request, dispatch phases, coordinate output)
  2. JS extraction function lives in its own file and is loaded by SKILL.md during audits
  3. Report template lives in its own file and produces identical report output to current v1 format
  4. All scoring tests from Phase 1 still pass after restructuring (no regressions)
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Fast Crawl
**Goal**: Full audits complete in under 1 minute with user control over which pages get audited
**Depends on**: Phase 2 (crawl logic lives in skill/crawl.md after modularization)
**Requirements**: CRAW-01, CRAW-02, CRAW-03, CRAW-04
**Success Criteria** (what must be TRUE):
  1. A full audit of a typical site (5-7 pages) completes in under 1 minute end-to-end
  2. Page selection picks 3-4 pages by template diversity instead of 7 most-linked
  3. Discovered pages are shown to the user who chooses which ones to audit before crawling starts
  4. Playwright reuses browser context across pages instead of creating new instances
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

### Phase 4: Feature Polish
**Goal**: Audit reports cover AI crawler policy, warn about stale rules, and compare mode is streamlined
**Depends on**: Phase 3
**Requirements**: AICR-01, AICR-02, AICR-03, RULE-01, RULE-02, COMP-01, COMP-02
**Success Criteria** (what must be TRUE):
  1. Audit report includes an AI crawler policy section that grades robots.txt strategy and lists which AI bots are allowed, blocked, or unaddressed
  2. When reference files are older than 90 days, the audit warns the user at startup and suggests running an update
  3. Compare mode outputs a single score-comparison table (no full side-by-side category reports)
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Lighthouse + Scoring Lock | 0/2 | Planning complete | - |
| 2. Modularization | 0/0 | Not started | - |
| 3. Fast Crawl | 0/0 | Not started | - |
| 4. Feature Polish | 0/0 | Not started | - |
