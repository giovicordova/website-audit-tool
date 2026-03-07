# Website Audit Tool

Claude Code skill package for auditing websites across SEO, AEO, and GEO. Not a standalone app — invoked via `audit example.com` inside Claude Code.

## Test Commands

```bash
tests/test-lighthouse-output.sh   # Lighthouse JSON shape validation (13 assertions)
tests/test-scoring.sh             # Golden-file scoring regression (6 assertions)
```

## Naming Conventions

- Audit reports: `{YYYY-MM-DD}-audit-{domain}.md` in `docs/w-audit/`

## Architecture

- **Orchestration**: `SKILL.md` defines the full audit flow (crawl, check, score, report)
- **Crawling**: Sequential via Playwright MCP (single browser instance, no parallel navigation)
- **Scoring**: Deterministic formula in `scripts/score.py` — severity weights, N/A exclusion, weighted category averages
- **References**: Category check lists in `references/` with freshness tracking (90-day staleness warning)

## File Structure

See `README.md` for the full tree. Key entry point is `SKILL.md`.

## Future Improvements

- Lighthouse subagent: run Lighthouse in a background task to avoid blocking the main audit flow
