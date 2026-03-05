> **This was the original proposal.** The tool was built as a Claude Code skill (SKILL.md), not a Python Agent SDK application. There are no custom MCP servers, no CLI interface, and no fix mode. See `docs/plans/2026-03-05-website-audit-tool-design.md` for the actual architecture decisions.

# Website Audit Tool — Project Brief (Original Proposal)

## What This Is

An automated website audit tool that checks any site against SEO, AEO (Answer Engine Optimization), and GEO (Generative Engine Optimization) best practices. Built on the Claude Agent SDK, it reads curated rules from authoritative sources, measures live data via MCP servers, and can either generate reports or auto-fix your own sites.

Will be used across multiple websites.

## The Problem

- SEO tools (Ahrefs, Semrush, Screaming Frog) tell you what's wrong but don't fix anything
- They cover traditional SEO only — not how AI search engines (Perplexity, ChatGPT, Google AI Overviews) choose what to cite
- Most SEO advice online is noise. Hard to separate what actually matters from opinion
- Auditing is manual and repetitive — same checks every time

## What This Tool Does

1. Audits any website against curated rules from primary sources
2. Measures real performance and indexing data via APIs
3. Generates a scored report with specific fixes
4. For your own sites: auto-fixes what it can, re-audits, loops until clean
5. Works on any site — run it against chapterpass.com, client sites, anything

## How It Works

```
WEBSITE AUDIT TOOL
|
|-- rules/                     <- CURATED (updated quarterly)
|   |-- seo-technical.md        Google Search Central
|   |-- seo-on-page.md          web.dev
|   |-- schema-requirements.md  Schema.org spec
|   |-- aeo-patterns.md         AI search citation patterns
|   |-- geo-citation.md         Generative engine optimization
|   |-- core-web-vitals.md      web.dev/vitals thresholds
|   |-- last-reviewed.md        Date each source was last checked
|
|-- mcps/                      <- LIVE DATA (called every audit)
|   |-- site-crawler             Crawl pages, check HTML structure
|   |-- pagespeed-insights       Lighthouse scores via API
|   |-- google-search-console    Indexing, queries, crawl errors
|   |-- schema-validator         Google Rich Results test
|   |-- crux                     Real-user Core Web Vitals (CrUX API)
|
|-- agent (Claude Agent SDK)   <- THE BRAIN
    Reads rules/
    Calls MCPs for measurements
    Compares data vs rules
    Outputs report or fixes code
```

## Two Buckets — Rules vs Measurements

### Bucket 1: Rules (what to check)

Curated from authoritative sources. Stored as markdown. Updated manually when sources change (roughly quarterly). NOT scraped live — these docs rarely change and scraping is fragile.

| Source | What it covers |
|---|---|
| Google Search Central | Crawlability, indexing, ranking factors |
| web.dev | Performance, accessibility, best practices |
| Schema.org spec | Structured data formats and requirements |
| Google helpful content guidelines | E-E-A-T, content quality signals |
| Bing Webmaster guidelines | Bing ranking + ChatGPT web search |
| Observable AI citation patterns | What Perplexity/ChatGPT/AI Overviews actually cite |

### Bucket 2: Measurements (what's actually happening)

Live API calls via MCP servers. Run every audit. Returns real data, not opinions.

| MCP | What it measures | Auth |
|---|---|---|
| Site crawler (existing seo-audit MCP) | HTML structure, meta tags, links, schema | None |
| PageSpeed Insights API | Lighthouse scores, load times | API key (free) |
| Google Search Console API | Indexing status, search queries, crawl errors | OAuth |
| Schema Validator | Rich Results test pass/fail | API key |
| CrUX API | Real-user Core Web Vitals | API key (free) |

## Three Modes

### 1. Audit Only (any website)
Read-only. Crawl the site, measure everything, compare against rules, output a report.
```bash
audit --url "https://example.com" --mode report
```

### 2. Fix Mode (your own sites)
Read + write. Audit, fix issues in the codebase, re-audit, loop until score plateaus.
```bash
audit --url "https://chapterpass.com" --mode fix --codebase ./web
```

### 3. Compare Mode (multiple sites)
Audit several sites, output a comparison table. Useful for competitive analysis.
```bash
audit --compare "https://site-a.com" "https://site-b.com" "https://site-c.com"
```

## Rule Categories

### SEO Technical
- robots.txt exists and doesn't block important pages
- XML sitemap exists, referenced in robots.txt, valid
- All pages return 200 (no broken links)
- Canonical tags on every page
- No duplicate titles/descriptions across pages
- HTTPS everywhere, no mixed content
- Mobile viewport meta tag present
- Core Web Vitals pass: LCP < 2.5s, INP < 200ms, CLS < 0.1

### SEO On-Page
- One H1 per page containing primary keyword
- Title tag: 50-60 chars, unique per page
- Meta description: 150-160 chars, unique per page
- Images have descriptive alt text
- Internal linking: every page reachable in 3 clicks from home
- Clean URL structure
- Heading hierarchy (H1 > H2 > H3, no skips)

### Structured Data
- JSON-LD present on every page
- Schema type matches page content
- Validates against Google Rich Results Test
- Breadcrumb schema on all non-home pages
- Organization/LocalBusiness schema on homepage

### AEO (Answer Engine Optimization)
- First paragraph directly answers the page's target question
- "What is X" / "How to X" heading patterns
- Concise definitions before detailed explanations
- FAQ section with FAQPage schema
- Lists and tables for comparison content
- Clear, unambiguous language (AI models prefer specificity)

### GEO (Generative Engine Optimization)
- Author name and credentials visible
- Published date and last-updated date present
- Sources/references linked for factual claims
- Content is specific (stats, examples, numbered steps)
- Unique data or perspective (not rewriting what already exists)
- Quotable passages — short, self-contained statements of fact

## Tech Stack

- **Claude Agent SDK** (Python) — orchestrates the audit
- **MCP servers** — connect to external APIs for live data
- **Lighthouse CLI** — performance scoring (runs via Bash tool)
- **Rules as markdown** — human-readable, version-controlled, easy to update
- **Output** — markdown reports + optional JSON for programmatic use

## Build Order

### Phase 1: Foundation
1. Write the rules files from primary sources (the actual value of the tool)
2. Build the main audit script using Agent SDK
3. Use existing tools only: seo-audit MCP + Lighthouse CLI
4. Test against chapterpass.com

### Phase 2: Live Data MCPs
5. Add PageSpeed Insights MCP (free, easy)
6. Add Google Search Console MCP (OAuth setup needed)
7. Add Schema Validator MCP
8. Add CrUX API MCP

### Phase 3: Multi-Site + Fix Loop
9. Add fix mode (agent edits code then re-audits)
10. Add compare mode for multiple sites
11. Add scoring system (0-100 per category, overall grade)

### Phase 4: Polish
12. CLI interface for easy use
13. Report templates (executive summary vs detailed)
14. Scheduled audits (weekly cron)

## What Makes This Different

| Existing tools | This tool |
|---|---|
| Tells you what's wrong | Tells you AND fixes it |
| Generic checklist | Curated rules from primary sources only |
| SEO only | SEO + AEO + GEO |
| Monthly subscription | Runs on your API key |
| Can't touch your code | Edits your actual codebase |
| Static report | Loops until clean |
| One site at a time | Compare mode across sites |

## Open Questions for Tomorrow
- Start with Python SDK or CLI-only (`claude -p`)?
- Do we want a web dashboard eventually or CLI-only is fine?
- Which site to use as first test target?
- Google Search Console OAuth — worth setting up in Phase 1 or defer?
