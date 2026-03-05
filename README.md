# Website Audit Tool

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that audits any website across five categories:

- **AEO** — Answer Engine Optimization (Perplexity, ChatGPT, Google AI Overviews)
- **GEO** — Generative Engine Optimization (E-E-A-T, citation readiness, trust signals)
- **SEO Technical** — Core Web Vitals, robots.txt, sitemaps, HTTPS, mobile-readiness
- **SEO On-Page** — Title tags, headings, meta descriptions, image alt text, URL structure
- **Structured Data** — JSON-LD validation, Schema.org types, rich results readiness

## What It Does

You say `audit example.com` and Claude:

1. **Crawls** the site using Playwright (homepage + up to 5 most-linked internal pages)
2. **Checks** every page against research-backed rules in each category
3. **Scores** each category and calculates an overall letter grade (A+ through F)
4. **Reports** a conversational summary in chat + saves a full markdown report

## Usage

### Full Audit (All 5 Categories)

```
audit example.com
```

### Specific Categories Only

```
audit example.com aeo geo
```

### Specific Pages Only

```
audit example.com /pricing /about
```

### Compare Two Sites

```
compare site-a.com site-b.com
```

Outputs a side-by-side comparison table with scores per category, an overall winner analysis, and individual audit reports for each site.

## Installation

### Option A: Symlink (Recommended)

Clone the repo and symlink it into your Claude Code skills directory:

```bash
git clone https://github.com/giovicordova/website-audit-tool.git
ln -s /path/to/website-audit-tool ~/.claude/skills/website-audit
```

### Option B: Copy

Copy the files directly:

```bash
git clone https://github.com/giovicordova/website-audit-tool.git
cp -r website-audit-tool ~/.claude/skills/website-audit
```

### PageSpeed Insights (Optional)

To enable Core Web Vitals checking, set a Google PageSpeed Insights API key:

```bash
export PAGESPEED_API_KEY="your-api-key-here"
```

Get a free API key at [Google Cloud Console](https://console.cloud.google.com/apis/credentials).

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [Playwright MCP](https://github.com/anthropics/claude-code/blob/main/docs/mcp.md) configured in Claude Code (for site crawling)

## Scoring

Each check has a severity level that determines its point value:

| Severity | Points |
|---|---|
| Critical | 3 |
| Important | 2 |
| Nice to Have | 1 |

**Category score** = (points earned / points possible) x 100

**Overall grade** uses weighted averages:

| Category | Weight |
|---|---|
| AEO | 25% |
| GEO | 25% |
| SEO Technical | 20% |
| SEO On-Page | 15% |
| Structured Data | 15% |

If only some categories are audited, weights are distributed proportionally.

## What Makes This Different

The AEO and GEO checks are backed by recent research on how AI search engines actually select and cite sources:

- **Princeton GEO study (KDD 2024)** — adding statistics, citations, and expert quotes each boost AI visibility up to 40%
- **BrightEdge analysis** — pages with JSON-LD schema are 2.7x more likely to be cited in AI answers
- **SurferSEO citation report** — 44.2% of AI citations come from the first 30% of content
- **Ahrefs brand visibility study (75K brands)** — brand mentions correlate more strongly with AI citation than traditional backlinks

The reference files in `references/` contain the full check lists with sources. They're designed to be updated as AI search patterns evolve.

## File Structure

```
SKILL.md                      # Orchestration logic (how Claude runs the audit)
references/
  aeo.md                      # Answer Engine Optimization checks
  geo.md                      # Generative Engine Optimization checks
  seo-technical.md            # Technical SEO checks
  seo-on-page.md              # On-Page SEO checks
  structured-data.md          # Structured Data checks
scripts/
  pagespeed.sh                # PageSpeed Insights API helper
```

## License

MIT
