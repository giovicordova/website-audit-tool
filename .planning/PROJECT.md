# Website Audit Tool

## What This Is

A Claude Code skill that audits any website for SEO, AEO (Answer Engine Optimization), and GEO (Generative Engine Optimization). Crawls pages via Playwright with template-diversity selection, checks against curated reference rules, scores each category with a deterministic formula, and outputs prioritized reports. Includes AI crawler policy grading, stale rule detection, and simplified compare mode for competitive analysis.

## Core Value

Accurate, consistent scoring that produces the same results for the same site regardless of when or how many times the audit runs.

## Requirements

### Validated

- Lighthouse CLI replaces PageSpeed API (local, no API key) -- v1.0
- Golden-file scoring tests catch regressions automatically -- v1.0
- SKILL.md modularized: extraction.js + report-template.md + orchestrator -- v1.0
- Template-diversity crawl with interactive page selection, under 1 minute -- v1.0
- AI Crawler Policy grading (14-bot list, training vs retrieval, A-F grades) -- v1.0
- Stale reference file detection (>90 days warning) -- v1.0
- Simplified compare mode (score table + top fixes, no full category reports) -- v1.0
- Deterministic scoring formula (Critical=3, Important=2, Nice=1, WARNING=half) -- v1.0

### Active

- [ ] Auto-research stale reference rules (Claude checks against official sources, user approves)
- [ ] curl + xmllint hybrid crawl for static HTML pages (0.06s vs 5-8s per page)
- [ ] Entity density scoring using structural signals
- [ ] Answer block detection (40-60 word direct answer in first 200 words)

### Out of Scope

- Fix mode (auto-editing codebases) -- reports are enough, user fixes manually
- Web dashboard -- CLI-only via Claude Code
- Custom MCP servers -- Playwright + curl + Lighthouse CLI covers everything
- Standalone CLI tool -- Claude Code is the interface
- HTML report export -- markdown is sufficient, git-tracked
- Agent SDK application -- Claude Code IS the agent
- Content quality scoring via AI -- breaks deterministic scoring (core value)

## Context

Shipped v1.0 on 2026-03-05. 4 phases, 5 plans, 9 feature commits in a single day.

**Tech stack:** Claude Code skill (SKILL.md orchestrator + modules), Bash scripts (lighthouse.sh), Python (score.py), Playwright MCP for crawling, curl for technical files.

**Architecture:** SKILL.md (200 lines, orchestration + scoring) loads modules/extraction.js (JS extraction function) and modules/report-template.md (report formatting). scripts/lighthouse.sh wraps Lighthouse CLI. scripts/score.py provides testable scoring implementation. 19 regression tests (13 lighthouse shape + 6 scoring golden-file).

**Known tech debt from v1.0:**
- scripts/pagespeed.sh is dead code (replaced by lighthouse.sh)
- README.md is stale (doesn't reflect v1.0 structure)
- Stale comment in modules/extraction.js (browser_evaluate -> evaluate_script)
- SKILL.md at 200 lines (target was ~150 after modularization, grew with Phase 3+4 features)

## Constraints

- **Runtime:** Claude Code skill -- no standalone runtime, no server, no build step
- **Dependencies:** Only system tools (curl, python3, npx) + Playwright MCP + Lighthouse CLI
- **Output:** Markdown reports in docs/w-audit/
- **Speed:** Under 1 minute for a full audit
- **Node:** Must use Lighthouse 12.x (Node 22.16, Lighthouse 13 needs 22.19+)
- **Backward compatibility:** Reports use same categories and grading scale across versions

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Lighthouse CLI over PageSpeed API | No API key, no rate limits, local execution | Good -- zero UNTESTABLE checks |
| Break SKILL.md into modules | Single 304-line file was fragile | Good -- 200-line orchestrator + 2 modules |
| Golden-file tests for scoring | Most likely source of silent regressions | Good -- 19 tests catch changes |
| Scoring formula stays in SKILL.md | Research showed extraction causes sync drift | Good -- score.py validates, SKILL.md executes |
| Template-diversity page selection | Better coverage than top-N by link count | Good -- 3-4 pages cover all template types |
| Phase D removed | Blog posts are just another template type | Good -- simpler flow |
| evaluate_script over browser_evaluate | Matches actual chrome-devtools-mcp tool name | Good -- consistent naming |
| AI crawler grade is informational | Not part of weighted score, different dimension | Good -- avoids score inflation |
| curl hybrid crawl deferred to v2 | Research flagged silent JS-content misses | Pending -- revisit in v2 |

---
*Last updated: 2026-03-05 after v1.0 milestone*
