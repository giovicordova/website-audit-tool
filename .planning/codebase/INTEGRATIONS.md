# External Integrations

**Analysis Date:** 2026-03-05

## APIs & External Services

**Google PageSpeed Insights API:**
- Purpose: Fetch Lighthouse scores (Performance, Accessibility, Best Practices, SEO) and real-user Core Web Vitals (CrUX data) for audited sites
- Client: `scripts/pagespeed.sh` — Bash script wrapping a `curl` call to the API + `python3` JSON parser
- Auth: `PAGESPEED_API_KEY` env var (free API key from Google Cloud Console)
- Endpoint: `https://www.googleapis.com/pagespeedonline/v5/runPagespeed`
- Parameters: URL, categories (PERFORMANCE, ACCESSIBILITY, BEST_PRACTICES, SEO), strategy (mobile)
- Failure handling: If the API returns 429 or quota exceeded, the audit notes "Core Web Vitals: untestable (API quota exceeded)" and continues
- Optional: The audit runs without it; CWV checks are skipped

**Playwright MCP Server:**
- Purpose: Browser automation for crawling target websites — navigate to pages and extract DOM data
- Client: Claude Code's MCP integration (not a direct API call from code)
- Auth: None — runs locally
- Key operations used:
  - `browser_navigate` — Load a page in the browser
  - `browser_evaluate` — Run the JS extraction function (defined in `SKILL.md` Section 1.1) to pull metadata, headings, links, images, JSON-LD, etc.
- Constraint: Single browser instance; pages MUST be crawled sequentially (not in parallel) to avoid stale DOM reads
- Critical dependency: Without Playwright MCP, no crawling is possible

## Data Storage

**Databases:**
- None — No database of any kind

**File Storage:**
- Local filesystem only
- Audit reports: `docs/w-audit/audit-{domain}-{YYYY-MM-DD}.md`
- Audit logs: `docs/logs/audit-log-{domain}-{date}.md`
- Session logs: `.claude/session-logs/` (gitignored)
- All output is markdown files

**Caching:**
- None — Every audit crawls fresh

## Authentication & Identity

**Auth Provider:**
- Not applicable — This is a local CLI tool with no user authentication
- The only auth is the optional `PAGESPEED_API_KEY` for the Google API

## Monitoring & Observability

**Error Tracking:**
- None — No error tracking service

**Logs:**
- Claude Code hook system generates structured audit logs automatically
- `.claude/hooks/stop-summary.sh` — Detects when an audit report was created/modified and prompts Claude to write a structured log capturing crawl summary, issues, timing, and skill performance notes
- `.claude/hooks/session-snapshot.sh` — Takes a snapshot of audit file mtimes at session start for change detection
- Audit logs saved to `docs/logs/audit-log-{domain}-{date}.md`
- Session review logs also in `docs/logs/` (e.g., `2026-03-05-session-review.md`)

## CI/CD & Deployment

**Hosting:**
- Not deployed — Runs locally via Claude Code CLI

**CI Pipeline:**
- None — No GitHub Actions, no CI configuration

## Environment Configuration

**Required env vars:**
- None strictly required

**Optional env vars:**
- `PAGESPEED_API_KEY` — Google PageSpeed Insights API key
- `CLAUDE_PROJECT_DIR` — Set automatically by Claude Code runtime

**Secrets location:**
- `.env` file (gitignored) — Likely stores `PAGESPEED_API_KEY`

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Planned but Not Yet Implemented

Per `PROJECT-BRIEF.md`, these integrations are planned for future phases but do not exist in the codebase:

- **Google Search Console API** — For indexing status, search queries, crawl errors (requires OAuth)
- **Schema Validator / Google Rich Results Test** — For structured data validation
- **CrUX API** — For real-user Core Web Vitals (separate from PageSpeed Insights)
- **Claude Agent SDK (Python)** — Originally planned as the orchestration layer; the current implementation uses Claude Code Skills instead

---

*Integration audit: 2026-03-05*
