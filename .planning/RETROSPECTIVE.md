# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 -- Website Audit Tool v2

**Shipped:** 2026-03-05
**Phases:** 4 | **Plans:** 5 | **Sessions:** ~3

### What Was Built
- Lighthouse CLI wrapper replacing broken PageSpeed API dependency
- Golden-file scoring engine with 19 regression tests
- Modular architecture (SKILL.md orchestrator + extraction.js + report-template.md)
- Template-diversity crawl with interactive page selection
- AI Crawler Policy grading (14-bot canonical list, A-F strategy grades)
- Stale reference file detection and simplified compare mode

### What Worked
- Research-before-plan approach caught critical issues early (e.g., curl hybrid crawl risks, Lighthouse INP limitation, scoring formula extraction pitfalls)
- Phase dependency chain was well-ordered: scoring tests (P1) provided safety net for modularization (P2), modularization enabled clean crawl rewrite (P3), crawl changes fed into feature polish (P4)
- Single-day execution with 4 phases was possible because each phase was tightly scoped (1-2 plans each)
- Verification after each phase caught the INP/TBT documentation mismatch early

### What Was Inefficient
- ROADMAP.md checkboxes not updated during phase execution (only Phase 4 was marked [x])
- SKILL.md line count grew past target (200 vs 150) because Phase 3+4 additions were larger than estimated
- Some tech debt accumulated that could have been cleaned in-flight (pagespeed.sh deletion, README update)
- No one-liners in SUMMARY frontmatter -- made milestone accomplishment extraction fail

### Patterns Established
- Module read pattern: SKILL.md loads modules via "Read modules/{file} from this skill's directory"
- Template classification: URL path patterns for zero-cost page typing
- Scoring: WARNING = half points (floor), N/A and UNTESTABLE excluded from denominator
- AI Crawler Policy is informational only, not part of weighted overall score
- Tool name: evaluate_script (chrome-devtools-mcp actual name), not browser_evaluate

### Key Lessons
1. Research phases are high-ROI: the crawl research saved us from a risky curl hybrid approach that would have silently missed JS-rendered content
2. Keep scoring formula in the orchestrator, not in extracted modules -- research showed sync drift is the #1 cause of scoring bugs in modular systems
3. Phase D was unnecessary complexity -- blog posts are just another template type in the selection menu
4. Lighthouse 12.x measures TBT not INP (INP is field-only) -- document this in requirements to avoid confusion

### Cost Observations
- Model mix: ~60% sonnet (executors, verifiers), ~30% opus (planning, orchestration), ~10% haiku (research)
- Sessions: ~3 (init + execution + audit)
- Notable: Entire v1.0 milestone completed in a single day (~4 hours wall time)

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | ~3 | 4 | Initial milestone -- established research-plan-execute-verify loop |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | 19 | Scoring + Lighthouse shape | score.py (stdlib only) |

### Top Lessons (Verified Across Milestones)

1. Research before planning prevents expensive rework (verified: curl hybrid, scoring extraction)
2. Tight phase scoping (1-2 plans) enables fast execution without context exhaustion
