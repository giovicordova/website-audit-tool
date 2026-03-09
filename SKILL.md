---
name: website-audit
argument-hint: "[domain] [categories...]"
allowed-tools: Read, Bash, Write, Glob, Grep, mcp__plugin_playwright_playwright__*, Agent(lighthouse-runner)
description: >
  Audits any website for SEO, AEO (Answer Engine Optimization), and GEO (Generative Engine Optimization).
  Triggers when the user asks to audit a website, check SEO/AEO/GEO, analyze a site's search readiness,
  or compare multiple sites. Matches phrases like "audit example.com", "check SEO for",
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

Default: all 5 categories, homepage + 3-4 pages selected by template diversity (user chooses).

## Audit Flow

### 1. Crawl

#### Phase A: Technical files + homepage (parallel)

Fire all of these in a single parallel batch:

1. **curl robots.txt** — `curl -sL {domain}/robots.txt` (NEVER use Playwright for non-HTML files)

   **AI Crawler Policy Analysis** — Using the robots.txt content from step 1, analyze AI bot rules:

   a. Check the following canonical AI bot list against the robots.txt:

   | Provider | Bot Name | Type | Purpose |
   |----------|----------|------|---------|
   | OpenAI | GPTBot | Training | Collects data for model training |
   | OpenAI | OAI-SearchBot | Retrieval | Real-time search indexing |
   | OpenAI | ChatGPT-User | Retrieval | Fetches pages during conversations |
   | Anthropic | ClaudeBot | Training | Collects data for Claude training |
   | Anthropic | Claude-SearchBot | Retrieval | Indexes content for search |
   | Anthropic | Claude-User | Retrieval | Fetches pages during conversations |

   > **Note:** Some sites use the legacy name "Claude-Web" for this bot. Treat "Claude-Web" as equivalent to "Claude-User" when classifying.

   | Google | Google-Extended | Training | Training data for Gemini/Bard |
   | Google | GoogleOther | Training | Additional Google AI training |
   | Perplexity | PerplexityBot | Retrieval | Indexes for answer engine |
   | Perplexity | Perplexity-User | Retrieval | Real-time page fetching |
   | Apple | Applebot-Extended | Training | Extended Apple AI training |
   | Meta | Meta-ExternalAgent | Training | Meta AI training data |
   | Amazon | Amazonbot | Retrieval | Alexa/Amazon search |
   | ByteDance | Bytespider | Training | TikTok/ByteDance AI training |

   b. For each bot, classify as:
      - **Blocked**: Has its own `User-agent` section with `Disallow: /`, OR falls under `User-agent: *` with `Disallow: /` and has NO specific override
      - **Allowed**: Has its own `User-agent` section without `Disallow: /`, OR has an explicit `Allow` directive, OR no blocking rule applies
      - **Unaddressed**: Not mentioned in robots.txt at all (no specific rule, no wildcard coverage)

   c. **IMPORTANT — Precedence rule:** Specific `User-agent` rules override wildcard (`*`) rules. A bot with its own `User-agent` section is governed by that section only, NOT by the `*` section.

   d. Also check for any `User-agent` entries containing "AI", "bot", "crawler", "spider" that are NOT in the canonical list — report these as "Other AI bots detected."

   e. Grade the strategy:
      - **A**: Training bots blocked, retrieval bots allowed, no major bots unaddressed
      - **B**: Most bots addressed, 1-2 unaddressed
      - **C**: Some bots addressed but significant gaps or inconsistencies
      - **D**: Only 1-2 bots addressed, most unaddressed
      - **F**: No AI bot rules in robots.txt at all

   f. This grade is **informational only** — it is NOT part of the weighted overall score.

2. **curl sitemap.xml** — `curl -sL {domain}/sitemap.xml` — parse URLs from `<loc>` tags
3. **curl llms.txt** — `curl -sI {domain}/llms.txt` — check HTTP status only (200 = exists)
4. **curl 404 test** — `curl -sI {domain}/nonexistent-page-404-test` — verify proper 404 status
5. **Playwright homepage** — `browser_navigate` to {domain}, then `browser_evaluate` with the JS extraction function (see Section 1.1)
6. **Read reference files** — load all 5 reference files from `${CLAUDE_SKILL_DIR}/references/`
7. **Lighthouse** — launch the `lighthouse-runner` subagent in the background with the domain URL. It runs `${CLAUDE_SKILL_DIR}/scripts/lighthouse.sh` and returns JSON with performance/accessibility/seo/best-practices scores and Core Web Vitals (LCP, CLS, TBT). No API key needed. Collect results before Phase C begins. If it fails, mark CWV checks as UNTESTABLE and continue.

#### Phase B: Discover and classify pages

Combine two sources to build the full page list:
1. **Sitemap URLs** — all `<loc>` entries from sitemap.xml
2. **Homepage links** — all internal links found by the JS extraction

**Classify each URL by template type** using URL path pattern matching:

| URL Pattern | Template Type |
|---|---|
| `/` | homepage |
| `/blog`, `/news`, `/posts` | blog-listing |
| `/blog/*`, `/news/*`, `/posts/*` | blog-post |
| `/about`, `/team`, `/company` | about |
| `/faq`, `/help`, `/support` | faq |
| `/pricing`, `/plans` | pricing |
| `/contact`, `/get-in-touch` | contact |
| `/products/*`, `/shop/*` | product |
| `/docs/*`, `/documentation/*` | docs |
| `/case-study/*`, `/customers/*` | case-study |
| `/[single-segment]` | landing-page |

**If the user specified pages** in the original command (e.g., "audit example.com /pricing /about"), skip the interactive step below and crawl those pages directly.

**Otherwise, present the grouped list and ask the user to choose:**

```
Found {N} pages across {M} template types:

  {type} ({count}): {url1}, {url2}, ...

Recommended ({3-4}): {one per unique template type, prioritizing types with distinct content patterns}

Which pages should I audit? Pick from above or say "recommended".
```

Wait for user selection before proceeding to Phase C. Cap "recommended" at 4 pages (1 per unique template type, homepage always included).

#### Phase C: Crawl selected pages (parallel via `browser_run_code`)

Use `browser_run_code` to crawl all selected pages in parallel within a single call. This opens concurrent tabs via `page.context().newPage()` and runs the extraction function on each.

Read `${CLAUDE_SKILL_DIR}/modules/extraction.js` and inline the function body into the script below.

```javascript
async (page) => {
  const context = page.context();
  const urls = [/* user-selected URLs */];
  const results = await Promise.all(urls.map(async (url) => {
    const p = await context.newPage();
    await p.goto(url, { waitUntil: 'domcontentloaded' });
    const data = await p.evaluate(() => { /* extraction.js body here */ });
    await p.close();
    return data;
  }));
  return results;
}
```

If any individual page fails to load, catch the error and return `{ url, error: message }` for that page. Mark that page's checks as UNTESTABLE and continue with the rest.

Do NOT take snapshots or screenshots during crawl — the extraction function captures all needed data.

### 1.1 JS Extraction Function

Read `${CLAUDE_SKILL_DIR}/modules/extraction.js`. This function is used in two places:
- **Phase A homepage**: passed directly to `browser_evaluate` as a single call
- **Phase C parallel crawl**: inlined into the `browser_run_code` script's `p.evaluate()` call

Do not extract metadata piecemeal across multiple calls.

### 2. Load Rules

Read the reference files for the requested categories:
- `${CLAUDE_SKILL_DIR}/references/aeo.md` — Answer Engine Optimization
- `${CLAUDE_SKILL_DIR}/references/geo.md` — Generative Engine Optimization
- `${CLAUDE_SKILL_DIR}/references/seo-technical.md` — Technical SEO
- `${CLAUDE_SKILL_DIR}/references/seo-on-page.md` — On-Page SEO
- `${CLAUDE_SKILL_DIR}/references/structured-data.md` — Structured Data

Only read the files for categories being audited.

### 2.1 Check Reference File Freshness

After loading the reference files above, check the `Last reviewed: YYYY-MM-DD` date in each loaded file. Compare each date against the current date.

If ANY file's last-reviewed date is more than 90 days ago, print this warning BEFORE proceeding to step 3:

```
Warning: {N} reference file(s) are stale (>90 days since last review):
  - references/{file}.md — last reviewed {date} ({days} days ago)

Audit results may not reflect current best practices.
Consider reviewing these files to ensure rules are up to date.

Proceeding with audit...
```

> **Testing note:** The staleness warning path (>90 days) has not been exercised in production since reference files are regularly updated. Manually test by temporarily backdating a reference file's `Last reviewed` date.

This is informational only — do NOT ask for confirmation, do NOT stop the audit. Print the warning and continue.

If all files are within 90 days, say nothing — no "all files are fresh" message.

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

Read `${CLAUDE_SKILL_DIR}/modules/report-template.md`. Follow the exact format for both single-site audits and compare mode. Do not improvise sections or reorder categories.
