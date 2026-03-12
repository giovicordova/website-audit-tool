# Website Audit Tool

Claude Code skill package for auditing websites across SEO, AEO, and GEO. Not a standalone app — invoked via `audit example.com` inside Claude Code.

## Test Commands

```bash
tests/test-lighthouse-output.sh   # Lighthouse JSON shape validation (13 assertions)
tests/test-scoring.sh             # Golden-file scoring regression (17 assertions)
tests/test-perplexity-output.sh   # Perplexity citation extraction (8 assertions)
tests/test-field-coverage.sh      # Reference→extraction.js field coverage (39 assertions)
tests/test-extraction.sh          # End-to-end extraction against mock HTML (51 assertions)
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
  ai-bots.md                    # AI crawler bot list (training + retrieval)
  geo.md                        # Generative Engine Optimization checks
  indexability.md               # Indexability checks (scored under SEO Technical)
  seo-technical.md              # Technical SEO checks (uses Lighthouse CLI)
  seo-on-page.md                # On-Page SEO checks
  structured-data.md            # Structured Data checks
scripts/
  lighthouse.sh                 # Local Lighthouse CLI wrapper (no API key needed)
  perplexity-check.sh           # Perplexity Sonar API wrapper (requires API key)
  score.py                      # Deterministic scoring engine (per-category + overall grade)
tests/
  lib/assert.sh                 # Shared test assertion helpers
  test-lighthouse-output.sh     # Lighthouse JSON shape validation (13 assertions)
  test-scoring.sh               # Golden-file scoring regression tests (17 assertions)
  test-perplexity-output.sh     # Perplexity citation extraction (8 assertions)
  fixtures/                     # Synthetic test data (not real site snapshots)
docs/
  perspective/                  # Meta-analysis reports about the tool and its competitive landscape
.claude/
  agents/lighthouse-runner.md   # Background subagent for parallel Lighthouse runs
  agents/perplexity-checker.md  # Background subagent for citation verification
  hooks/validate-report-name.sh # Enforces report naming convention
  settings.json                 # Permission allowlist and hook config
```

## Companion Tools

For full GSC URL Inspection data (index status, crawl history, Google-selected canonical), install [mcp-gsc](https://github.com/AminForou/mcp-gsc) as a companion MCP server.
