---
name: website-audit
context: fork
disable-model-invocation: true
argument-hint: "[domain] [categories...]"
allowed-tools: Read, Bash, Write, Glob, Grep, Agent(lighthouse-runner), Agent(perplexity-checker), mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_evaluate, mcp__plugin_playwright_playwright__browser_run_code
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

**Optional flags:**
- `+citations` — Run Perplexity citation verification (requires `PERPLEXITY_API_KEY`). Advisory only, does not affect score.
- `+refresh` — Search the web for latest SEO/AEO/GEO best practices and propose updates to reference files before running the audit. See Section 0 below.
- `+benchmark <domain>` — Crawl a benchmark site alongside the target for structural comparison. See Section 0.2 below.

## Pre-Audit: Reference Refresh (Section 0)

This section runs **only** when `+refresh` is requested OR when any reference file's `Last reviewed` date is more than 30 days old.

### 0.1 Auto-Refresh Reference Rules

For each reference file in `${CLAUDE_SKILL_DIR}/references/` that has a `Last reviewed` date:

1. **Check staleness** — if the file's `Last reviewed` date is within 30 days AND `+refresh` was NOT explicitly requested, skip that file.

2. **Search the web** for the latest best practices relevant to that file's category. Use these search targets:

   | File | Search queries |
   |---|---|
   | aeo.md | "AI citation best practices {year}", "how to get cited by ChatGPT Perplexity {year}" |
   | geo.md | "Google E-E-A-T updates {year}", "AI Overview citation factors", "GEO optimization {year}" |
   | seo-technical.md | "Google Search Central updates {year}", "Core Web Vitals changes", "new Lighthouse audits" |
   | seo-on-page.md | "on-page SEO best practices {year}", "Google ranking factors update" |
   | structured-data.md | "schema.org deprecated types {year}", "Google rich results changes {year}", "new JSON-LD types" |
   | indexability.md | "Google indexing changes {year}", "GSC coverage report updates" |
   | ai-bots.md | "new AI crawler bots {year}", "AI bot robots.txt {year}" |

   Replace `{year}` with the current year.

3. **Compare findings** against the current file content. Look for:
   - New checks that should be added (new research, new Google requirements)
   - Existing checks that are outdated (deprecated features, changed thresholds)
   - New data points or statistics to update (citation rates, study results)

4. **Present a diff to the user** showing proposed changes:
   ```
   Reference refresh for {filename}:

   + ADD: {new check description} (SEVERITY) — Source: {url}
   ~ UPDATE: {existing check} — {what changed} — Source: {url}
   - REMOVE: {outdated check} — {reason}

   Apply these changes? [y/N]
   ```

5. **If confirmed**, apply changes to the file:
   - Update checks in the appropriate severity section
   - Bump `Last reviewed: {today's date}`
   - Append a changelog entry:
     ```
     ### {YYYY-MM-DD}
     - Added: {description} — Source: {url}
     - Updated: {description}
     - Removed: {description}
     ```
   - If the file has a `## Required Extraction Fields` section, verify new checks don't require fields not in extraction.js. If they do, flag this: "Warning: new check requires `{field}` which extraction.js doesn't capture. The check will be added but may not be fully automated."

6. **If declined**, skip that file and continue.

**Guard rails:**
- Cap to 3 web searches per file (avoid rate limiting)
- Total refresh should complete in <60 seconds
- Never silently modify files — always show changes and ask

### 0.2 Benchmark Comparison

When `+benchmark` is requested (with or without a specific domain):

1. **Select benchmark site:**
   - If user specified one: `+benchmark stripe.com` → use that domain
   - If not: auto-select based on the target site's detected category:

     | Site category signals | Recommended benchmark |
     |---|---|
     | SaaS / software (Product schema, /pricing page) | stripe.com |
     | Content / blog / media | nerdwallet.com |
     | E-commerce (Product schema, /shop) | amazon.com |
     | Documentation / developer | docs.github.com |
     | Healthcare | mayoclinic.org |
     | Default / unknown | hubspot.com |

   Category detection uses the target site's JSON-LD `@type` values and URL patterns from Phase B.

2. **Crawl 1 page** from the benchmark site using the same extraction.js (homepage only — minimizes load on third-party sites).

3. **Compare structural patterns** and include a "Benchmark Comparison" section in the report (see report-template.md for format).

4. **This is advisory only** — benchmark data does not affect the numerical score.

## Audit Flow

### 1. Crawl

#### Phase A: Technical files + homepage (parallel)

Fire all of these in a single parallel batch:

1. **curl robots.txt** — `curl -sL {domain}/robots.txt` (NEVER use Playwright for non-HTML files)

   **AI Crawler Policy Analysis** — Using the robots.txt content from step 1, analyze AI bot rules:

   a. Read the canonical AI bot list from `${CLAUDE_SKILL_DIR}/references/ai-bots.md`. This file contains Training Bots, Retrieval Bots, legacy name mappings, and strategy grading criteria.

   b. For each bot in the list, classify as:
      - **Blocked**: Has its own `User-agent` section with `Disallow: /`, OR falls under `User-agent: *` with `Disallow: /` and has NO specific override
      - **Allowed**: Has its own `User-agent` section without `Disallow: /`, OR has an explicit `Allow` directive, OR no blocking rule applies
      - **Unaddressed**: Not mentioned in robots.txt at all (no specific rule, no wildcard coverage)

   c. **IMPORTANT — Precedence rule:** Specific `User-agent` rules override wildcard (`*`) rules. A bot with its own `User-agent` section is governed by that section only, NOT by the `*` section.

   d. Check the Legacy Names table in the reference file — treat legacy names as equivalent to current names when classifying.

   e. Also check for any `User-agent` entries containing "AI", "bot", "crawler", "spider" that are NOT in the canonical list — report these as "Other AI bots detected."

   f. Grade the strategy using the criteria in the reference file's Strategy Grading table.

2. **curl sitemap.xml** — `curl -sL {domain}/sitemap.xml` — parse URLs from `<loc>` tags

2b. **Sitemap URL health spot-check** — After parsing sitemap URLs from step 2, sample up to 20 URLs (evenly spaced if more than 20). Run `curl -sI {url}` in parallel for each sampled URL. Record which URLs return non-200 status codes. This data feeds the "sitemap URLs return 200" indexability check.

3. **curl llms.txt** — `curl -sI {domain}/llms.txt` — check HTTP status only (200 = exists)
4. **curl 404 test** — `curl -sI {domain}/nonexistent-page-404-test` — verify proper 404 status
5. **Playwright homepage** — `browser_navigate` to {domain}, then `browser_evaluate` with the JS extraction function (see Section 1.1)
6. **Read reference files** — load all 5 reference files from `${CLAUDE_SKILL_DIR}/references/`
7. **Lighthouse** — launch the `lighthouse-runner` subagent in the background with the domain URL. It runs `${CLAUDE_SKILL_DIR}/scripts/lighthouse.sh` and returns JSON with performance/accessibility/seo/best-practices scores and Core Web Vitals (LCP, CLS, TBT). No API key needed. Collect results before Phase C begins. If it fails, mark CWV checks as UNTESTABLE and continue.
8. **Perplexity citation check** *(only if `+citations` was requested)* — Check that `PERPLEXITY_API_KEY` is set in the environment. If missing, warn the user ("Skipping citation check — PERPLEXITY_API_KEY not set") and continue without it. If set, launch the `perplexity-checker` subagent in the background with the domain and a summary of the homepage content (title, meta description, key heading topics). Collect results before Phase C begins alongside Lighthouse.

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
    const response = await p.goto(url, { waitUntil: 'domcontentloaded' });
    const httpStatus = response ? response.status() : 0;
    const headers = response ? await response.allHeaders() : {};
    const xRobotsTag = headers['x-robots-tag'] || null;
    const finalUrl = p.url();
    let redirectCount = 0;
    if (response) {
      let req = response.request();
      while (req.redirectedFrom()) {
        redirectCount++;
        req = req.redirectedFrom();
      }
    }
    const data = await p.evaluate(() => { /* extraction.js body here */ });
    await p.close();
    return { ...data, httpStatus, xRobotsTag, finalUrl, redirectCount };
  }));
  return results;
}
```

The crawl captures response metadata (HTTP status, headers, redirect chain) from Playwright's response object. This data powers the indexability checks without extra network requests.

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
- `${CLAUDE_SKILL_DIR}/references/indexability.md` — Indexability (scored under SEO Technical)
- `${CLAUDE_SKILL_DIR}/references/ai-bots.md` — AI crawler bot list (always loaded for Phase A analysis)

Only read the category-specific files for categories being audited. Always load `ai-bots.md` since the AI crawler policy analysis runs in every audit.

### 2.1 Check Reference File Freshness

After loading the reference files above, check the `Last reviewed: YYYY-MM-DD` date in each loaded file. Compare each date against the current date.

If ANY file's last-reviewed date is more than 30 days ago:

1. If `+refresh` was requested, the pre-audit refresh (Section 0.1) should have already handled these files. Print a note and continue.

2. If `+refresh` was NOT requested, print this warning BEFORE proceeding to step 3:

```
Warning: {N} reference file(s) are stale (>30 days since last review):
  - references/{file}.md — last reviewed {date} ({days} days ago)

Audit results may not reflect current best practices.
Run with +refresh to update rules, or review files manually.

Proceeding with audit...
```

This is informational only — do NOT ask for confirmation, do NOT stop the audit. Print the warning and continue.

If all files are within 30 days, say nothing — no "all files are fresh" message.

### 3. Check Each Category

For each category, go through every check in the reference file. For each check:
- Evaluate the crawled data against the rule
- Mark as PASS, FAIL, or WARNING based on the severity level defined in the reference file
- Record specific evidence (e.g., "Page /about has no H1 tag")

### 4. Score

Collect all check results into a JSON structure and pipe to `${CLAUDE_SKILL_DIR}/scripts/score.py`:

```json
{
  "categories": {
    "aeo": {"checks": [{"severity": "critical", "result": "PASS"}, ...]},
    "geo": {"checks": [...]},
    "seo_technical": {"checks": [...]},
    "seo_on_page": {"checks": [...]},
    "structured_data": {"checks": [...]}
  }
}
```

Valid severity values: `critical`, `important`, `nice_to_have`
Valid result values: `PASS`, `WARNING`, `FAIL`, `N/A`, `UNTESTABLE`

Run: `echo '<json>' | python3 ${CLAUDE_SKILL_DIR}/scripts/score.py`

The script returns JSON with per-category scores, the weighted overall score, and the letter grade:

```json
{
  "categories": {"aeo": {"score": 77, "weight": 25}, ...},
  "overall": 77,
  "grade": "B"
}
```

The scoring formula, category weights, and grade thresholds are all defined in `score.py`. Do NOT compute scores or grades in-prompt — always use the script to ensure deterministic results.

**Handling N/A and UNTESTABLE checks:**
- If a check is marked **CONDITIONAL** in the reference file and the condition doesn't apply, mark it **N/A**
- N/A checks are excluded from both the numerator and denominator (they don't affect the score)
- UNTESTABLE checks (e.g., PageSpeed API quota exceeded) are also excluded from the denominator
- Always note which checks were N/A or UNTESTABLE in the report

If only some categories were audited, include only those in the JSON. The script redistributes weights proportionally.

### 5. Report and Compare Mode

Read `${CLAUDE_SKILL_DIR}/modules/report-template.md`. Follow the exact format for both single-site audits and compare mode. Do not improvise sections or reorder categories.

### 6. Offer to Implement Fixes

After presenting the conversational summary and saving the report, check whether the audited site's codebase is in the current working directory. Look for signals: domain match in `package.json` homepage/name field, config files referencing the domain (e.g., `next.config.*`, `nuxt.config.*`, `astro.config.*`, `.env*`), or deployment config pointing to the domain.

**If the codebase is detected locally:**

Ask the user:

*"The report has {N} fixes prioritized by impact. Want me to work through them?"*

If the user says **no**, end. The report stands on its own.

If the user says **yes**:

1. Work through each checkbox item in the Fix Priority List, starting from the top (highest impact first).
2. After completing each fix, update the report file — change `- [ ]` to `- [x]` for that item.
3. Skip fixes that require access to external systems (DNS, hosting config, CDN settings) — leave them unchecked and note why.
4. When done, show a brief summary of what was fixed and what remains.

**If the codebase is NOT detected locally:**

Do not offer to implement. The fix list with checkboxes is still useful as a manual tracking sheet.
