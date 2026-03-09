# Website Audit Tool

Claude Code skill package for auditing websites across SEO, AEO, and GEO. Not a standalone app — invoked via `audit example.com` inside Claude Code.

## Test Commands

```bash
tests/test-lighthouse-output.sh   # Lighthouse JSON shape validation (13 assertions)
tests/test-scoring.sh             # Golden-file scoring regression (6 assertions)
tests/test-perplexity-output.sh   # Perplexity citation extraction (8 assertions)
```

## Naming Conventions

- Audit reports: `{YYYY-MM-DD}-audit-{domain}.md` in `docs/w-audit/`

## Architecture

- **Orchestration**: `SKILL.md` defines the full audit flow (crawl, check, score, report)
- **Crawling**: Parallel via Playwright CLI (`browser_run_code` with concurrent tabs for multi-page crawl)
- **Scoring**: Deterministic formula in `scripts/score.py` — severity weights, N/A exclusion, weighted category averages
- **References**: Category check lists in `references/` with freshness tracking (90-day staleness warning)
- **Subagents**: Lighthouse runner + Perplexity checker in `.claude/agents/` — background tasks for parallel performance analysis and citation verification

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
  perplexity-check.sh           # Perplexity Sonar API wrapper (requires API key)
  score.py                      # Deterministic scoring engine
tests/
  test-lighthouse-output.sh     # Lighthouse JSON shape validation (13 assertions)
  test-scoring.sh               # Golden-file scoring regression tests (6 assertions)
  test-perplexity-output.sh     # Perplexity citation extraction (8 assertions)
  fixtures/                     # Synthetic test data (not real site snapshots)
.claude/
  agents/lighthouse-runner.md   # Background subagent for parallel Lighthouse runs
  agents/perplexity-checker.md  # Background subagent for citation verification
  hooks/validate-report-name.sh # Enforces report naming convention
  settings.json                 # Permission allowlist and hook config
```
