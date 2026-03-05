### 5. Report

**First: conversational summary in chat.** 2-3 sentences covering overall grade, number of critical issues, and the single highest-impact fix.

**Then: save the full report** to `docs/w-audit/{YYYY-MM-DD}-{HH-MM}-audit-{domain}.md`.
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

## AI Crawler Policy

**Strategy Grade: {grade}** — {one-line summary, e.g., "Intentional strategy with 2 bots unaddressed"}

### Training Bots
| Bot | Provider | Status |
|-----|----------|--------|
| {bot_name} | {provider} | {Blocked/Allowed/Unaddressed} |
...

### Retrieval Bots
| Bot | Provider | Status |
|-----|----------|--------|
| {bot_name} | {provider} | {Blocked/Allowed/Unaddressed} |
...

### Recommendation
{Actionable recommendation: which bots to block/allow and why. Default recommendation is block training bots + allow retrieval bots for AI search visibility. List specific missing rules the site should add.}

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

**Then: save the audit log** to `docs/logs/{YYYY-MM-DD}-{HH-MM}-{domain}.md` with a summary of pages crawled, checks run, and any errors encountered. This is the authoritative log — a Stop hook may also generate one, but SKILL.md is the source of truth since hooks are not version-controlled.

## Compare Mode

When the user says "compare site-a.com site-b.com [site-c.com]":

1. Run the full audit flow for each site independently (audits still execute fully to generate scores; individual site reports are saved to their own files as usual)
2. Output a comparison table:

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

4. Below the analysis, add a Top Fixes section:

### Top Fixes Per Site

**{domain-a}:**
1. {highest-impact fix from that site's audit} ({category})
2. {second fix} ({category})
3. {third fix} ({category})

**{domain-b}:**
1. {highest-impact fix} ({category})
2. {second fix} ({category})
3. {third fix} ({category})

5. Save the comparison report (table + analysis + top fixes ONLY) to `docs/w-audit/{YYYY-MM-DD}-{HH-MM}-compare-{domain1}-vs-{domain2}.md`. Create the `docs/w-audit/` directory if it doesn't exist. Do NOT include full category-by-category breakdowns per site in the compare file — users who want per-site details can read the individual audit files.

<!-- Testing note: Compare mode template has not been exercised in a live audit yet. Run a compare audit (e.g., "compare site-a.com site-b.com") to verify formatting. -->
