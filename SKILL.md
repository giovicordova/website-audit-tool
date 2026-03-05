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

Use Playwright MCP to visit the target URL. Collect:
- The full HTML of each page
- All internal links from the homepage
- Pick up to 5 most-linked internal pages and visit those too
- For each page: URL, title tag, meta description, all headings, all images, all links, any JSON-LD blocks, full visible text content

If the user specified pages (e.g., /pricing /about), only visit those instead.

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
- Score = (points earned / points possible) * 100

Overall grade (weighted):
- AEO: 25%
- GEO: 25%
- SEO Technical: 20%
- SEO On-Page: 15%
- Structured Data: 15%

Letter grade: A+ (95+), A (90+), A- (85+), B+ (80+), B (75+), B- (70+), C+ (65+), C (60+), C- (55+), D (50+), F (<50)

If only some categories were audited, weight proportionally across those.

### 5. Report

**First: conversational summary in chat.** 2-3 sentences covering overall grade, number of critical issues, and the single highest-impact fix.

**Then: save the full report** to `audit-{domain}-{YYYY-MM-DD}.md` in the current working directory.

Report template:

```markdown
# Website Audit: {domain}
**Date:** {date} | **Pages audited:** {count} | **Overall Grade: {letter} ({score}/100)**

## Summary
{critical_count} critical issues, {warning_count} warnings, {pass_count} checks passed.
Top priority: {highest_impact_fix}.

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

4. Save the full comparison report (table + individual audits) to `compare-{domain1}-vs-{domain2}-{date}.md`
