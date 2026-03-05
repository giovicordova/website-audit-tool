# Architecture

**Analysis Date:** 2026-03-05

## Pattern Overview

**Overall:** Skill-based agent architecture (no compiled code)

This is a Claude Code Skill, not a traditional application. There is no runtime, no compiled code, no server. The entire system is a set of markdown instruction files and shell scripts that Claude Code interprets and executes at audit time. The "architecture" is the orchestration logic in `SKILL.md` combined with reference rule files and helper scripts.

**Key Characteristics:**
- No application code -- pure markdown-driven agent behavior
- Claude Code acts as the runtime, reading `SKILL.md` as its execution plan
- Data collection happens via Playwright MCP (browser automation) and shell commands (curl, scripts)
- All "logic" lives in natural language instructions, not code
- Reference files serve as the knowledge base (rule definitions with severity levels)

## Layers

**Orchestration Layer (SKILL.md):**
- Purpose: Defines the complete audit workflow -- parsing user input, crawling strategy, scoring formula, report template
- Location: `SKILL.md`
- Contains: Step-by-step instructions for Claude Code to follow, including the JS extraction function, scoring weights, and report format
- Depends on: Claude Code runtime, Playwright MCP, reference files
- Used by: Claude Code when user triggers the skill (e.g., "audit example.com")

**Knowledge Layer (references/):**
- Purpose: Stores curated audit rules organized by category, each with severity levels (Critical/Important/Nice to Have)
- Location: `references/`
- Contains: 5 rule files covering AEO, GEO, SEO Technical, SEO On-Page, and Structured Data
- Depends on: Nothing (static, manually updated)
- Used by: Orchestration layer during the "Check Each Category" phase

**Data Collection Layer (scripts/ + Playwright MCP + curl):**
- Purpose: Gathers live data from target websites
- Location: `scripts/pagespeed.sh` for PageSpeed API; Playwright MCP for browser-based crawling; curl for robots.txt/sitemap/llms.txt/404 checks
- Contains: One shell script (`pagespeed.sh`) that calls Google PageSpeed Insights API
- Depends on: External APIs (PageSpeed Insights), Playwright MCP server, target website availability
- Used by: Orchestration layer during the "Crawl" phase

**Output Layer (docs/):**
- Purpose: Stores generated audit reports, session logs, and planning documents
- Location: `docs/w-audit/` for audit reports, `docs/logs/` for session logs, `docs/plans/` for planning docs
- Contains: Markdown reports generated per audit run
- Depends on: Orchestration layer completing an audit
- Used by: End user (Gio) to review findings

**Hook Layer (.claude/):**
- Purpose: Automates session management -- snapshots and stop summaries
- Location: `.claude/settings.json`, `.claude/hooks/session-snapshot.sh`, `.claude/hooks/stop-summary.sh`
- Contains: Claude Code hook configuration and shell scripts that run on PreToolUse and Stop events
- Depends on: Claude Code hook system
- Used by: Claude Code automatically during sessions

## Data Flow

**Full Audit Flow:**

1. User says "audit example.com" -- Claude Code matches the skill trigger in `SKILL.md`
2. **Phase A (parallel):** curl fetches robots.txt, sitemap.xml, llms.txt, 404 test; Playwright navigates to homepage and runs JS extraction; `scripts/pagespeed.sh` fetches Core Web Vitals; reference files are loaded
3. **Phase B:** Combine sitemap URLs and homepage internal links to build a crawl list of up to 5 pages
4. **Phase C (sequential):** Playwright visits each page one-at-a-time, running the JS extraction function on each
5. **Phase D:** If a blog listing was found, crawl one blog post for Article schema verification
6. **Scoring:** For each category, compare crawled data against reference file checks. Score using 3/2/1 point weights for Critical/Important/Nice to Have
7. **Report:** Output conversational summary in chat, save full report to `docs/w-audit/audit-{domain}-{date}.md`

**Compare Flow:**

1. Run the full audit flow independently for each site
2. Generate a comparison table with per-category scores
3. Save combined report to `docs/w-audit/compare-{domain1}-vs-{domain2}-{date}.md`

**State Management:**
- No persistent state between audit runs
- Each audit is a fresh execution -- no database, no cache
- All output is written to markdown files in `docs/`
- Session hooks capture snapshots during execution (`.claude/hooks/`)

## Key Abstractions

**JS Extraction Function:**
- Purpose: Single JavaScript function that extracts all page metadata in one `browser_evaluate` call
- Location: Defined inline in `SKILL.md` (lines 67-174)
- Pattern: One comprehensive extraction per page rather than multiple targeted calls. Returns a structured object with title, meta tags, headings, images, links, JSON-LD, FAQ detection, word count, OG/Twitter tags, etc.

**Reference File Format:**
- Purpose: Standardized rule definition with severity tiers
- Examples: `references/aeo.md`, `references/geo.md`, `references/seo-technical.md`, `references/seo-on-page.md`, `references/structured-data.md`
- Pattern: Each file has a Source section (provenance), then Checks grouped into CRITICAL, IMPORTANT, NICE TO HAVE. Each check is a markdown checkbox with an evaluation description and research citation. Some checks are marked CONDITIONAL (evaluated as N/A when condition does not apply).

**Scoring System:**
- Purpose: Weighted scoring across 5 categories
- Location: Defined in `SKILL.md` (lines 199-218)
- Pattern: Points per severity (Critical=3, Important=2, Nice to Have=1). Category score = earned/possible * 100. Overall = weighted average (AEO 25%, GEO 25%, SEO Technical 20%, SEO On-Page 15%, Structured Data 15%). N/A and UNTESTABLE checks excluded from denominator.

**Report Template:**
- Purpose: Standardized output format for all audits
- Location: Defined in `SKILL.md` (lines 231-278)
- Pattern: Site Profile section, then per-category sections with Passed/Warnings/Failed subsections, then a prioritized Fix Priority List

## Entry Points

**Primary -- Skill Trigger:**
- Location: `SKILL.md` (frontmatter, lines 1-9)
- Triggers: User phrases like "audit example.com", "check SEO for", "compare site-a.com site-b.com"
- Responsibilities: Initiates the full audit or compare flow

**Helper -- PageSpeed Script:**
- Location: `scripts/pagespeed.sh`
- Triggers: Called by Claude Code during Phase A of the audit
- Responsibilities: Fetches Lighthouse scores and CrUX Core Web Vitals data from Google PageSpeed Insights API. Requires `PAGESPEED_API_KEY` env var.

## Error Handling

**Strategy:** Graceful degradation with UNTESTABLE markers

**Patterns:**
- If PageSpeed API fails (429/quota exceeded), mark Core Web Vitals checks as UNTESTABLE and exclude from score denominator -- do not fail the audit
- If `PAGESPEED_API_KEY` is not set, `pagespeed.sh` exits with error message -- audit continues without CWV data
- CONDITIONAL checks that don't apply to a site are marked N/A and excluded from scoring
- Playwright crawling is sequential (not parallel) to avoid stale DOM reads from shared browser instance -- this is a learned constraint documented in `SKILL.md` line 52

## Cross-Cutting Concerns

**Logging:** Automated via Claude Code hooks. `PreToolUse` hook runs `session-snapshot.sh` for session tracking. `Stop` hook runs `stop-summary.sh` to generate audit logs at `docs/logs/`. The skill itself does not handle logging.

**Validation:** Rule-based. Each check in the reference files defines its own validation criteria in natural language. Claude Code interprets and applies these during the audit.

**Authentication:** Only the PageSpeed API requires auth (`PAGESPEED_API_KEY` env var). All other data collection (curl, Playwright) is unauthenticated. No OAuth or user auth in the system.

---

*Architecture analysis: 2026-03-05*
