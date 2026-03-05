# Website Audit Tool v2

## What This Is

A Claude Code skill that audits any website for SEO, AEO (Answer Engine Optimization), and GEO (Generative Engine Optimization). It crawls pages, checks them against curated rules from authoritative sources, scores each category, and outputs a prioritized report with specific fixes. Used across multiple websites for competitive analysis and ongoing optimization.

## Core Value

Accurate, consistent scoring that produces the same results for the same site regardless of when or how many times the audit runs.

## Requirements

### Validated

- Audit any website against 5 categories (AEO, GEO, SEO Technical, SEO On-Page, Structured Data)
- Curated reference rules from authoritative sources (Google Search Central, web.dev, Schema.org)
- Scored report with letter grade, category breakdowns, and prioritized fix list
- Compare mode for side-by-side competitive analysis
- JS extraction function that pulls all page metadata in a single browser_evaluate call
- Markdown reports saved to docs/w-audit/

### Active

- [ ] Break SKILL.md into focused modules (crawl, scoring, report template as separate files)
- [ ] Replace PageSpeed API with Lighthouse CLI (no API key, no rate limits, local execution)
- [ ] Add golden-file tests for scoring regression detection
- [ ] Auto-research stale reference rules (warn + update when older than 90 days)
- [ ] Speed up audits to under 1 minute (curl + Playwright hybrid for crawl phase)
- [ ] Always show discovered pages and let user choose which to audit before crawling
- [ ] Simplify compare mode to score-comparison table only (drop full side-by-side reports)
- [ ] Make scoring deterministic (explicit WARNING = half points, eliminate improvisation)

### Out of Scope

- Fix mode (auto-editing codebases) -- reports are enough, user fixes manually
- Web dashboard -- CLI-only via Claude Code
- Custom MCP servers -- use Playwright + curl + Lighthouse CLI
- Standalone CLI tool -- Claude Code is the interface
- HTML report export -- markdown is sufficient, git-tracked
- Agent SDK application -- Claude Code IS the agent

## Context

This is a brownfield evolution of an existing tool. The v1 works (2 successful audits completed) but has documented concerns:

**Accuracy problems:**
- WARNING scoring was undefined (improvised per session) -- now fixed but needs tests
- 4 Core Web Vitals checks permanently UNTESTABLE (no PageSpeed API key) -- Lighthouse CLI replaces this
- Reference rules have no update process -- auto-staleness detection needed

**Speed problems:**
- Playwright crawling is 5-8s per page (sequential, single browser instance)
- 7-page audit takes ~60s just for crawling
- Playwright snapshots consume context window without being used

**Fragility problems:**
- SKILL.md (304 lines) is the entire application -- one bad edit breaks everything
- No tests, no type checking, no way to validate changes except running a full audit
- Reference file edits silently change scoring denominators

**What works well:**
- Skill-based architecture (no compiled code, no deployment)
- JS extraction function (comprehensive, single call per page)
- Report format (clear, actionable, consistent across audits)
- curl for robots.txt/sitemap/llms.txt (fast, reliable)

## Constraints

- **Runtime:** Claude Code skill -- no standalone runtime, no server, no build step
- **Dependencies:** Only system tools (curl, python3, npx) + Playwright MCP + Lighthouse CLI
- **Output:** Markdown reports in docs/w-audit/, same location as v1
- **Speed:** Under 1 minute for a full audit (current: ~2-3 minutes)
- **Backward compatibility:** v2 reports should be comparable to v1 reports (same categories, same grading scale)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Lighthouse CLI over PageSpeed API | No API key needed, no rate limits, runs locally, same data source | -- Pending |
| Break SKILL.md into modules | Single 304-line file is fragile, one edit risks breaking unrelated features | -- Pending |
| Golden-file tests for scoring | Most likely source of silent regressions when reference files change | -- Pending |
| curl + Playwright hybrid crawl | curl is fast for static HTML, Playwright only needed for JS-rendered content | -- Pending |
| Auto-research stale rules | Reference files need updating but manual process gets forgotten | -- Pending |
| Always ask which pages to audit | Users want control over what gets audited, not just auto-picked pages | -- Pending |
| Simplified compare mode | Score table only, drop full side-by-side reports -- less output, same insight | -- Pending |
| No fix mode | Reports are sufficient, user fixes manually from prioritized list | -- Pending |

---
*Last updated: 2026-03-05 after initialization*
