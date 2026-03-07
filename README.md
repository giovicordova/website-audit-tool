# Website Audit Tool

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that audits any website across five categories:

- **AEO** -- Answer Engine Optimization (Perplexity, ChatGPT, Google AI Overviews)
- **GEO** -- Generative Engine Optimization (E-E-A-T, citation readiness, trust signals)
- **SEO Technical** -- Core Web Vitals, robots.txt, sitemaps, HTTPS, mobile-readiness
- **SEO On-Page** -- Title tags, headings, meta descriptions, image alt text, URL structure
- **Structured Data** -- JSON-LD validation, Schema.org types, rich results readiness

## What It Does

You say `audit example.com` and Claude:

1. **Crawls** the site -- fetches technical files (robots.txt, sitemap, llms.txt) via curl, runs Lighthouse locally for performance scores, and navigates pages via Playwright
2. **Selects pages** -- classifies discovered URLs by template type (homepage, about, blog-listing, blog-post, product, FAQ, etc.) and lets you choose which 3-4 to audit
3. **Analyzes AI crawler policy** -- grades your robots.txt strategy for AI bots (training vs retrieval), reports which bots are allowed/blocked/unaddressed
4. **Checks** every page against research-backed rules in each category
5. **Scores** each category with a deterministic formula and calculates an overall letter grade (A+ through F)
6. **Reports** a conversational summary in chat + saves a full markdown report

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

Outputs a score-comparison table with analysis and top 3 fixes per site.

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/giovicordova/website-audit-tool/main/install.sh | bash
```

Or clone first, then run locally:

```bash
git clone https://github.com/giovicordova/website-audit-tool.git
cd website-audit-tool
./install.sh --local
```

The installer checks dependencies, clones the repo, and symlinks it to `~/.claude/skills/website-audit`.

### Manual Install

**Option A: Symlink (Recommended)**

```bash
git clone https://github.com/giovicordova/website-audit-tool.git
ln -s /path/to/website-audit-tool ~/.claude/skills/website-audit
```

**Option B: Copy**

```bash
git clone https://github.com/giovicordova/website-audit-tool.git
cp -r website-audit-tool ~/.claude/skills/website-audit
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [Playwright MCP](https://github.com/anthropics/claude-code/blob/main/docs/mcp.md) configured in Claude Code (for site crawling)
- Node.js 22+ with npx (for Lighthouse CLI)
- Python 3 (for deterministic scoring engine)

## Scoring

Each check has a severity level that determines its point value:

| Severity | Points |
|---|---|
| Critical | 3 |
| Important | 2 |
| Nice to Have | 1 |

Results map to points: **PASS** = full points, **WARNING** = half points (floor), **FAIL** = 0. Checks marked N/A or UNTESTABLE are excluded from the denominator.

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

- **Princeton GEO study (KDD 2024)** -- adding statistics, citations, and expert quotes each boost AI visibility up to 40%
- **BrightEdge analysis** -- pages with JSON-LD schema are 2.7x more likely to be cited in AI answers
- **SurferSEO citation report** -- 44.2% of AI citations come from the first 30% of content
- **Ahrefs brand visibility study (75K brands)** -- brand mentions correlate more strongly with AI citation than traditional backlinks

The reference files in `references/` contain the full check lists with sources. They're designed to be updated as AI search patterns evolve. The audit warns you when reference files are older than 90 days.

## File Structure

```
SKILL.md                        # Orchestration logic (how Claude runs the audit)
modules/
  extraction.js                 # JS function run on each page via Playwright
  report-template.md            # Report and compare mode formatting
references/
  aeo.md                        # Answer Engine Optimization checks
  geo.md                        # Generative Engine Optimization checks
  seo-technical.md              # Technical SEO checks (uses Lighthouse CLI)
  seo-on-page.md                # On-Page SEO checks
  structured-data.md            # Structured Data checks
scripts/
  lighthouse.sh                 # Local Lighthouse CLI wrapper (no API key needed)
  score.py                      # Deterministic scoring engine
tests/
  test-lighthouse-output.sh     # Lighthouse JSON shape validation (13 assertions)
  test-scoring.sh               # Golden-file scoring regression tests (6 assertions)
  fixtures/                     # Synthetic test data (not real site snapshots)
docs/
  w-audit/                      # Saved audit reports (YYYY-MM-DD-audit-domain.md)
  logs/                         # Skill performance logs (YYYY-MM-DD-log-domain.md)
```

## License

MIT
