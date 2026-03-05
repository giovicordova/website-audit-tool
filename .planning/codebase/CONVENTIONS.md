# Coding Conventions

**Analysis Date:** 2026-03-05

## Project Nature

This is a **Claude Code Skill** (not a traditional application). There is no compiled source code, no package manager, and no runtime. The codebase consists of:
- Markdown files defining audit rules and orchestration logic
- Shell scripts for API integration
- JavaScript snippets embedded in markdown (executed via Playwright MCP)
- Claude Code hooks (bash scripts triggered by tool use events)

All "code" follows conventions appropriate to its file type.

## Naming Patterns

**Files:**
- Markdown reference files: lowercase with hyphens (`seo-technical.md`, `seo-on-page.md`, `structured-data.md`)
- Shell scripts: lowercase with hyphens (`pagespeed.sh`, `session-snapshot.sh`, `stop-summary.sh`)
- Skill definition: UPPERCASE (`SKILL.md`)
- Project docs: UPPERCASE (`README.md`, `PROJECT-BRIEF.md`)
- Audit reports: `audit-{domain}-{YYYY-MM-DD}.md` (e.g., `audit-giovannicordova.com-2026-03-05.md`)
- Comparison reports: `compare-{domain1}-vs-{domain2}-{date}.md`
- Audit logs: `audit-log-{domain}-{date}.md`

**Directories:**
- Lowercase, short names: `references/`, `scripts/`, `docs/`
- Nested with purpose-based naming: `docs/w-audit/`, `docs/logs/`, `docs/plans/`
- Claude Code system dirs: `.claude/hooks/`, `.claude/session-logs/`

**JavaScript (embedded in SKILL.md):**
- camelCase for variables and functions (`jsonLd`, `bodyWords`, `firstP`, `metaDesc`)
- Descriptive names reflecting DOM elements (`h1Elements`, `internalLinks`, `externalLinks`)
- Abbreviated names acceptable for DOM queries (`metaDesc`, `firstP`)

**Shell scripts:**
- UPPER_SNAKE_CASE for environment variables (`PAGESPEED_API_KEY`, `AUDIT_DIR`, `SNAPSHOT`)
- UPPER_SNAKE_CASE for local script variables (`URL`, `API_KEY`, `CHANGED_FILES`, `CURRENT_STATE`)
- Lowercase for loop variables (`f`, `file`, `mtime`)

## Code Style

**Markdown:**
- Use ATX-style headings (`#`, `##`, `###`)
- Reference files use three severity tiers: `### CRITICAL`, `### IMPORTANT`, `### NICE TO HAVE`
- Each check is a checkbox item: `- [ ] Check description — evidence/rationale`
- Source attribution at the top of every reference file under `## Source`
- `Last reviewed: YYYY-MM-DD` date on every reference file
- Conditional checks marked inline with `**CONDITIONAL:**` followed by the condition and N/A instructions

**Shell scripts:**
- Shebang line: `#!/bin/bash`
- Usage comment immediately after shebang
- Input validation at the top (check required args, check env vars)
- Exit codes: `exit 0` for success, `exit 1` for usage errors
- Use `2>/dev/null` for optional command fallbacks (e.g., `stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f" 2>/dev/null` for cross-platform compatibility)
- Quote all variable expansions (`"$URL"`, `"$SNAPSHOT"`)
- Use `jq` for JSON output construction in hooks (see `stop-summary.sh`)

**JavaScript (browser_evaluate snippets):**
- IIFE pattern: `(() => { ... })()`
- Spread operator for NodeList conversion: `[...document.querySelectorAll('selector')]`
- Ternary expressions for null-safe value extraction
- `try/catch` for JSON parsing with `.filter(Boolean)` to remove nulls
- Single return object at the end with all extracted data
- No external dependencies; pure DOM API usage

## Report Format

**Audit reports follow a strict template** defined in `SKILL.md` (lines 229-278):
- Header: `# Website Audit: {domain}` with date, page count, overall grade
- Summary section: critical count, warning count, pass count, top priority fix
- Site Profile section: domain, sitemap count, pages crawled, page types, detected tech, JSON-LD types, AI bot policy
- Per-category sections: `## {Category} ({score}/100)` with `### Passed`, `### Warnings`, `### Failed` subsections
- Fix Priority List at the end: ordered by severity (critical > important > nice to have), color-coded with emoji circles

**Scoring convention:**
- Critical checks: 3 points
- Important checks: 2 points
- Nice to Have checks: 1 point
- N/A and UNTESTABLE checks excluded from denominator
- Letter grades: A+ (95+), A (90+), A- (85+), B+ (80+), B (75+), B- (70+), C+ (65+), C (60+), C- (55+), D (50+), F (<50)

## Import Organization

Not applicable. No module system. JavaScript snippets are self-contained IIFEs. Shell scripts use only standard Unix tools (`curl`, `python3`, `jq`, `stat`, `grep`, `sed`, `sort`, `basename`).

## Error Handling

**Shell scripts:**
- Guard clauses at top: check for required arguments, check for required env vars, exit with usage message on failure
- Fallback patterns for cross-platform compatibility: `stat -f '%m' 2>/dev/null || stat -c '%Y' 2>/dev/null`
- Silent file checks: `[ -f "$f" ] || continue` to skip missing files in loops
- `2>/dev/null` on optional commands rather than letting errors propagate

**JavaScript (browser_evaluate):**
- `try/catch` wrapping JSON.parse calls with null fallback
- Null-coalescing with `|| ''` and `|| null` for missing DOM elements
- `.filter(Boolean)` to remove failed parse results
- Conditional property access: `(a.rel || '').includes('noopener')`

**Audit flow (SKILL.md):**
- PageSpeed API failures: mark checks as UNTESTABLE, exclude from score denominator, note in report
- Conditional checks: mark N/A when condition does not apply (e.g., hreflang for single-language sites)
- Crawl failures: note in audit log under "Issues During Audit"

## Logging

**No application-level logging framework.** Logging is handled via:
- Claude Code hooks that write to `.claude/session-logs/`
- Audit logs saved to `docs/logs/audit-log-{domain}-{date}.md` (generated by the Stop hook)
- The Stop hook (`stop-summary.sh`) blocks Claude from stopping until the audit log is written

## Comments

**Shell scripts:**
- File-level comment block explaining purpose, trigger conditions, and behavior
- Inline comments for non-obvious logic (e.g., `# Already snapshotted -- exit fast`)
- Section dividers for multi-phase logic

**Markdown:**
- Inline rationale after checks using em dash: `— 44.2% of AI citations come from the first 30% of content`
- Source citations embedded directly in check descriptions
- `**CONDITIONAL:**` markers for checks that may not apply

**JavaScript:**
- Single-line comments for labeled sections: `// JSON-LD blocks`, `// Headings`, `// Images`

## Function Design

**Shell scripts:**
- No named functions. Scripts are short (under 80 lines) procedural flows.
- Each script does one thing: `pagespeed.sh` fetches PageSpeed data, `session-snapshot.sh` records file state, `stop-summary.sh` triggers audit log generation.

**JavaScript:**
- Single IIFE per page extraction. One function does everything.
- Returns a flat object with all extracted data (no nested helper functions).
- The extraction function in `SKILL.md` is the canonical version; all page crawls use the same function.

## Module Design

**No module system.** The codebase is organized as:
- `SKILL.md`: orchestration logic (the "main" file Claude reads to run an audit)
- `references/*.md`: rule definitions (read by Claude during step 2 of the audit flow)
- `scripts/*.sh`: helper scripts called via Bash tool
- `.claude/hooks/*.sh`: lifecycle hooks triggered automatically by Claude Code
- `docs/w-audit/*.md`: output reports
- `docs/logs/*.md`: output audit logs

---

*Convention analysis: 2026-03-05*
