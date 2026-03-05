# Technology Stack

**Analysis Date:** 2026-03-05

## Languages

**Primary:**
- Markdown — All audit logic, rules, and reports are plain markdown files
- Bash — Shell scripts for API calls and hook automation

**Secondary:**
- JavaScript — Inline browser evaluation via Playwright MCP (not standalone files)
- Python 3 — Inline JSON parsing within `scripts/pagespeed.sh` (piped via `python3 -c`)

## Runtime

**Environment:**
- Claude Code CLI — The entire tool runs as a Claude Code skill, not as a standalone application
- macOS (Darwin 24.6.0) — Development and execution platform
- No dedicated language runtime (no Node.js, no Python venv) — relies on system `python3` and `curl`

**Package Manager:**
- None — No `package.json`, `requirements.txt`, `pyproject.toml`, or any package manifest
- No lockfile — No dependencies to manage

## Frameworks

**Core:**
- Claude Code Skill System — `SKILL.md` is the orchestration entry point; Claude reads it and follows the audit flow
- Playwright MCP — Browser automation for crawling websites (configured externally in Claude Code)

**Testing:**
- None — No test framework or test files exist

**Build/Dev:**
- None — No build step, no compilation, no bundling

## Key Dependencies

**Critical (External Services):**
- Playwright MCP Server — Required for all site crawling; provides `browser_navigate` and `browser_evaluate` capabilities
- `curl` — Used for fetching `robots.txt`, `sitemap.xml`, `llms.txt`, and 404 tests
- `python3` — System Python used for JSON parsing in `scripts/pagespeed.sh`
- `jq` — Used in hook scripts for JSON manipulation

**Optional:**
- Google PageSpeed Insights API — Core Web Vitals and Lighthouse scores via `scripts/pagespeed.sh`

## Configuration

**Environment:**
- `PAGESPEED_API_KEY` — Optional. Google PageSpeed Insights API key for Core Web Vitals checks
- `.env` file exists (gitignored) — Likely stores the API key
- `CLAUDE_PROJECT_DIR` — Set automatically by Claude Code; used in hook scripts to resolve project paths

**Claude Code Configuration:**
- `.claude/settings.json` — Defines PreToolUse and Stop hooks
- `.claude/hooks.json` — Alternate hook configuration (PostToolUse and Stop hooks)
- `.claude/hooks/session-snapshot.sh` — PreToolUse hook; snapshots audit file mtimes at session start
- `.claude/hooks/stop-summary.sh` — Stop hook; detects new/modified audit reports and prompts Claude to write an audit log

**No build configuration.** No `tsconfig.json`, no bundler config, no CI config.

## Platform Requirements

**Development:**
- Claude Code CLI installed and authenticated
- Playwright MCP server configured in Claude Code's MCP settings
- `curl`, `python3`, `jq` available on PATH (standard macOS tools)
- Optional: `PAGESPEED_API_KEY` env var for PageSpeed checks

**Production:**
- Same as development — this is a local CLI tool, not a deployed service
- No server, no hosting, no deployment pipeline

---

*Stack analysis: 2026-03-05*
