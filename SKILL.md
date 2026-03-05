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
7. **PageSpeed API** (optional) — run `scripts/pagespeed.sh {domain}` — if it fails (429/quota), note "Core Web Vitals: untestable (API quota exceeded)" and move on

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

Run this single `browser_evaluate` call on every page. One call per page gets all the data:

```javascript
// Pass as arrow function, NOT IIFE -- Playwright MCP rejects self-invoking functions
() => {
  const title = document.title || '';
  const metaDesc = document.querySelector('meta[name="description"]');
  const canonical = document.querySelector('link[rel="canonical"]');
  const viewport = document.querySelector('meta[name="viewport"]');

  // JSON-LD blocks
  const jsonLdScripts = [...document.querySelectorAll('script[type="application/ld+json"]')];
  const jsonLd = jsonLdScripts.map(s => { try { return JSON.parse(s.textContent); } catch { return null; } }).filter(Boolean);

  // Headings
  const headings = [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')].map(h => ({
    tag: h.tagName.toLowerCase(),
    text: h.textContent.trim()
  }));

  // H1 quick access
  const h1Elements = document.querySelectorAll('h1');

  // Images
  const images = [...document.querySelectorAll('img')].map(img => ({
    src: img.src,
    alt: img.alt || '',
    hasAlt: img.hasAttribute('alt'),
    altIsDescriptive: img.alt && !(/^(img|image|photo|picture|screenshot)[\s_-]?\d*/i.test(img.alt))
  }));

  // Links
  const allLinks = [...document.querySelectorAll('a[href]')];
  const origin = window.location.origin;
  const internalLinks = allLinks.filter(a => a.href.startsWith(origin)).map(a => ({
    href: a.href.replace(origin, ''),
    text: a.textContent.trim()
  }));
  const externalLinks = allLinks.filter(a => !a.href.startsWith(origin) && a.href.startsWith('http')).map(a => ({
    href: a.href,
    text: a.textContent.trim(),
    hasTargetBlank: a.target === '_blank',
    hasNoopener: (a.rel || '').includes('noopener')
  }));

  // Body text
  const bodyText = document.body.innerText || '';
  const bodyWords = bodyText.split(/\s+/).filter(w => w.length > 0);

  // First paragraph
  const firstP = document.querySelector('main p, article p, .content p, p');

  // FAQ detection
  const hasFAQ = headings.some(h => /\?$/.test(h.text)) ||
    !!document.querySelector('[itemtype*="FAQPage"]') ||
    jsonLd.some(j => j['@type'] === 'FAQPage' || (Array.isArray(j['@type']) && j['@type'].includes('FAQPage')));

  // Time tags
  const timeTags = [...document.querySelectorAll('time')].map(t => ({
    datetime: t.getAttribute('datetime') || '',
    text: t.textContent.trim()
  }));

  // OG and Twitter meta
  const ogTags = {};
  document.querySelectorAll('meta[property^="og:"]').forEach(m => {
    ogTags[m.getAttribute('property')] = m.content;
  });
  const twitterTags = {};
  document.querySelectorAll('meta[name^="twitter:"]').forEach(m => {
    twitterTags[m.getAttribute('name')] = m.content;
  });

  // HTTP links (mixed content check)
  const httpLinks = allLinks.filter(a => a.href.startsWith('http://')).map(a => a.href);

  // Tables and lists
  const tableCount = document.querySelectorAll('table').length;
  const listCount = document.querySelectorAll('ul, ol').length;

  return {
    url: window.location.href,
    title,
    titleLength: title.length,
    metaDescription: metaDesc ? metaDesc.content : null,
    metaDescriptionLength: metaDesc ? metaDesc.content.length : 0,
    viewport: viewport ? viewport.content : null,
    canonical: canonical ? canonical.href : null,
    jsonLd,
    headings,
    h1Text: h1Elements.length > 0 ? h1Elements[0].textContent.trim() : null,
    h1Count: h1Elements.length,
    images,
    imagesWithoutAlt: images.filter(i => !i.hasAlt).length,
    internalLinks,
    externalLinks,
    bodyWordCount: bodyWords.length,
    bodyTextLength: bodyText.length,
    bodyText: bodyText.substring(0, 3000),
    firstParagraph: firstP ? firstP.textContent.trim() : null,
    hasFAQ,
    timeTags,
    publishedDate: timeTags.length > 0 ? timeTags[0].datetime : null,
    ogTags,
    twitterTags,
    httpLinks,
    tableCount,
    listCount,
    hasTablesOrCharts: tableCount > 0
  };
}
```

Claude MUST use this exact function (or a superset of it) for every page. Do not extract metadata piecemeal across multiple calls.

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

### 5. Report

**First: conversational summary in chat.** 2-3 sentences covering overall grade, number of critical issues, and the single highest-impact fix.

**Then: save the full report** to `docs/w-audit/audit-{domain}-{YYYY-MM-DD}.md`.
Create the `docs/w-audit/` directory if it doesn't exist.

Report template:

```markdown
# Website Audit: {domain}
**Date:** {date} | **Pages audited:** {count} | **Overall Grade: {letter} ({score}/100)**

## Summary
{critical_count} critical issues, {warning_count} warnings, {pass_count} checks passed.
Top priority: {highest_impact_fix}.

## Site Profile
- **Domain:** {domain}
- **Pages in sitemap:** {sitemap_url_count}
- **Pages crawled:** {pages_crawled_count}
- **Page types found:** {comma-separated list, e.g., "Homepage, About, Blog listing, Blog post, Contact, FAQ, Reviews"}
- **Detected tech:** {any observable framework/platform, e.g., "Next.js on Vercel" — infer from response headers, meta tags, or source hints}
- **JSON-LD schema types found:** {comma-separated unique @type values across all pages}
- **AI bot policy:** {summary of robots.txt AI bot rules, e.g., "Allows ChatGPT-User, PerplexityBot. Blocks GPTBot, Google-Extended."}

## AEO — Answer Engine Optimization ({score}/100)
### Passed
- {check}: {evidence}
### Warnings
- {check}: {evidence}
### Failed
- {check}: {evidence}

## GEO — Generative Engine Optimization ({score}/100)
### Passed
...
### Warnings
...
### Failed
...

## SEO Technical ({score}/100)
...

## SEO On-Page ({score}/100)
...

## Structured Data ({score}/100)
...

## Fix Priority List
1. {red_circle} {highest_impact_fix}
2. {red_circle} {next_fix}
3. {yellow_circle} {warning_fix}
...
```

Order the fix priority list by: critical fails first (sorted by impact), then warnings, then nice-to-haves. Use red circle for critical, yellow circle for important, green circle for nice to have.

**Note:** The audit log (`docs/logs/audit-log-{domain}-{date}.md`) is generated automatically by the Stop hook — the skill does not need to create it.

## Compare Mode

When the user says "compare site-a.com site-b.com [site-c.com]":

1. Run the full audit flow for each site independently
2. Before the individual reports, output a comparison table:

### Comparison Table Format

| Category | site-a.com | site-b.com | site-c.com |
|---|---|---|---|
| AEO | 70/100 | 85/100 | 60/100 |
| GEO | 65/100 | 90/100 | 55/100 |
| SEO Technical | 95/100 | 80/100 | 70/100 |
| SEO On-Page | 88/100 | 75/100 | 82/100 |
| Structured Data | 75/100 | 60/100 | 90/100 |
| **Overall** | **B+ (80)** | **B+ (82)** | **C+ (68)** |

3. Below the table, write a 2-3 sentence analysis: who wins overall, where each site has an advantage, and the single biggest gap between them.

4. Save the full comparison report (table + individual audits) to `docs/w-audit/compare-{domain1}-vs-{domain2}-{date}.md`. Create the `docs/w-audit/` directory if it doesn't exist.
