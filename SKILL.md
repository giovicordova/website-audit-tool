---
name: website-audit
description: >
  Audit any website for SEO, AEO (Answer Engine Optimization), and GEO (Generative Engine Optimization).
  Use this skill when the user asks to audit a website, check SEO/AEO/GEO, analyze a site's search readiness,
  or compare multiple sites. Triggers on phrases like "audit example.com", "check SEO for",
  "how does my site score", "compare these sites", or any request to evaluate a website's
  optimization for traditional and AI search engines.
---

# Website Audit

## How to Parse the Request

The user will say something like:
- "audit example.com" — full audit, all categories
- "audit example.com aeo geo" — only named categories
- "audit example.com /pricing /about" — only specific pages
- "compare site-a.com site-b.com" — side-by-side comparison

Default: all 5 categories, homepage + up to 5 most-linked internal pages.

## Audit Flow

### 1. Crawl

#### Phase A: Technical files + homepage (parallel)

Fire all of these in a single parallel batch:

1. **curl robots.txt** — `curl -sL {domain}/robots.txt` (NEVER use Playwright for non-HTML files)
2. **curl sitemap.xml** — `curl -sL {domain}/sitemap.xml` — parse URLs from `<loc>` tags
3. **curl llms.txt** — `curl -sI {domain}/llms.txt` — check HTTP status only (200 = exists)
4. **curl 404 test** — `curl -sI {domain}/nonexistent-page-404-test` — verify proper 404 status
5. **Playwright homepage** — navigate to {domain}, run the JS extraction function (see Section 1.1)
6. **Read reference files** — load all 5 reference files from `references/`
7. **Lighthouse** — run `scripts/lighthouse.sh {domain}` — returns JSON with performance/accessibility/seo/best-practices scores and Core Web Vitals (LCP, CLS, TBT). No API key needed. If it fails, mark CWV checks as UNTESTABLE and continue.

#### Phase B: Discover pages to crawl

Combine two sources to build the crawl list:
1. **Sitemap URLs** — all `<loc>` entries from sitemap.xml
2. **Homepage links** — all internal links found by the JS extraction

Pick pages to crawl (in this priority order):
- Up to 5 most-linked internal pages (linked from nav/footer = high priority)
- If a `/blog` or blog listing page is in the list, also crawl **at least 1 individual blog post** (to verify Article schema, author visibility, and content depth)
- If the user specified pages (e.g., `/pricing /about`), only visit those instead

#### Phase C: Crawl internal pages (sequential, NOT parallel)

**IMPORTANT:** Crawl pages one at a time using Playwright in the main thread. Do NOT use background agents or parallel tasks for browser navigation — Playwright MCP shares a single browser instance, and concurrent navigations cause stale DOM reads (confirmed in first audit run).

For each page, run a single `browser_evaluate` call with the JS extraction function (see Section 1.1).

#### Phase D: Crawl blog post (if applicable)

If a blog listing page was found in Phase B:
1. From the blog listing page's extracted data, pick the first blog post link
2. Navigate to it and run the JS extraction function
3. This verifies Article schema, author visibility, published date, and content depth on actual blog content

### 1.1 JS Extraction Function

Read `modules/extraction.js` from this skill's directory. Run this exact function (or a superset of it) via a single `browser_evaluate` call on every page. Do not extract metadata piecemeal across multiple calls.

**IMPORTANT:** The function must be an arrow function, NOT an IIFE -- Playwright MCP rejects self-invoking functions.

### 2. Load Rules

Read the reference files for the requested categories from this skill's `references/` directory:
- `references/aeo.md` — Answer Engine Optimization
- `references/geo.md` — Generative Engine Optimization
- `references/seo-technical.md` — Technical SEO
- `references/seo-on-page.md` — On-Page SEO
- `references/structured-data.md` — Structured Data

Only read the files for categories being audited.

### 3. Check Each Category

For each category, go through every check in the reference file. For each check:
- Evaluate the crawled data against the rule
- Mark as PASS, FAIL, or WARNING based on the severity level defined in the reference file
- Record specific evidence (e.g., "Page /about has no H1 tag")

### 4. Score

For each category:
- Critical checks: 3 points each
- Important checks: 2 points each
- Nice to Have checks: 1 point each
- PASS = full points, WARNING = half points (rounded down), FAIL = 0 points
- Score = (points earned / points possible) * 100

Overall grade (weighted):
- AEO: 25%
- GEO: 25%
- SEO Technical: 20%
- SEO On-Page: 15%
- Structured Data: 15%

Letter grade: A+ (95+), A (90+), A- (85+), B+ (80+), B (75+), B- (70+), C+ (65+), C (60+), C- (55+), D (50+), F (<50)

**Handling N/A and UNTESTABLE checks:**
- If a check is marked **CONDITIONAL** in the reference file and the condition doesn't apply, mark it **N/A**
- N/A checks are excluded from both the numerator and denominator (they don't affect the score)
- UNTESTABLE checks (e.g., PageSpeed API quota exceeded) are also excluded from the denominator
- Always note which checks were N/A or UNTESTABLE in the report

If only some categories were audited, weight proportionally across those.

### 5. Report and Compare Mode

Read `modules/report-template.md` from this skill's directory. Follow the exact format for both single-site audits and compare mode. Do not improvise sections or reorder categories.
