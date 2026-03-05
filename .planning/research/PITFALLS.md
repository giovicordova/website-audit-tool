# Domain Pitfalls

**Domain:** Website audit tool (Claude Code skill)
**Researched:** 2026-03-05

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Lighthouse Scores Vary Between Runs
**What goes wrong:** Lighthouse performance scores can vary 5-10 points between identical runs on the same URL due to network conditions, CPU load, and Chrome process state.
**Why it happens:** Lighthouse simulates page load in a throttled Chrome instance. Background processes, network jitter, and thermal throttling all affect results.
**Consequences:** Audit scores appear non-deterministic. Users question accuracy when re-auditing the same site gives different numbers.
**Prevention:** Run Lighthouse with `--quiet` flag to reduce overhead. Accept that performance scores have a margin of error. In the report, note "Performance scores may vary +/-5 points between runs." Do NOT cache or average multiple runs -- that adds complexity without meaningful improvement.
**Detection:** Two consecutive audits of the same site showing different performance grades.

### Pitfall 2: curl Misses JS-Rendered Content Silently
**What goes wrong:** curl fetches the initial HTML response. For SPAs (React, Vue, Angular) or Next.js with client-side hydration, critical content (headings, structured data, meta tags) may be injected by JavaScript and absent from the curl response.
**Why it happens:** curl does not execute JavaScript. The initial HTML may be a shell with a `<div id="root"></div>` and nothing else.
**Consequences:** Audit reports false FAILs (missing H1, missing JSON-LD, missing meta description) when the content actually exists on the rendered page.
**Prevention:** For every page, compare curl extraction against Playwright extraction for at least the homepage. If curl misses critical fields that Playwright finds, flag the site as "JS-rendered" and use Playwright for all pages. This comparison should happen once per audit, not per page.
**Detection:** curl extraction returns null/empty for title, H1, or JSON-LD on a page that visually has content.

### Pitfall 3: Reference File Edits Change All Scores Silently
**What goes wrong:** Adding one CRITICAL check to `references/seo-technical.md` increases the denominator by 3 points. Every previous audit of every site now has a different score ceiling. Historical comparisons break.
**Why it happens:** The scoring formula divides earned points by possible points. Changing the number of checks changes "possible points."
**Consequences:** Score drift. A site that scored 85 last week might score 78 this week with no changes to the site -- only because a reference file was updated.
**Prevention:** Golden file tests. After ANY reference file edit, run `tests/test-scoring.sh` to see which fixtures' expected scores changed. Update fixtures deliberately, not accidentally. Add a changelog comment to reference files when checks are added/removed.
**Detection:** `test-scoring.sh` fails after a reference file edit.

## Moderate Pitfalls

### Pitfall 4: xmllint HTML Parser Warnings on Real-World HTML
**What goes wrong:** xmllint's HTML parser produces stderr warnings on common patterns like `&` in URLs, unclosed tags, and attribute values without quotes. The extraction still works, but stderr output is noisy.
**Prevention:** Always redirect stderr: `xmllint --html --xpath '...' - 2>/dev/null`. The warnings do not affect extraction accuracy.

### Pitfall 5: Lighthouse Requires a Running Chrome Instance
**What goes wrong:** If Chrome/Chromium is not installed, or is already running and locking the profile, Lighthouse fails with cryptic errors.
**Prevention:** Use `--chrome-flags="--headless"` to avoid display dependency. The `--quiet` flag suppresses most non-fatal warnings. If Chrome is already running, Lighthouse usually launches a separate instance, but test this during setup.

### Pitfall 6: npx lighthouse Downloads on First Run
**What goes wrong:** First `npx lighthouse` invocation downloads the package (~50MB), causing a long delay and potential timeout.
**Prevention:** Already handled -- this system has lighthouse 12.5.1 cached. If the cache is cleared, the first audit will take an extra 30-60s. Not worth pre-installing globally unless it becomes a problem.

### Pitfall 7: Splitting SKILL.md Too Aggressively
**What goes wrong:** If SKILL.md is split into too many small files, Claude spends tokens reading 8 files instead of 1. Each file read is a tool call. Excessive splitting slows down the audit and wastes context.
**Prevention:** Split into 3-4 modules maximum: SKILL.md (orchestration), skill/crawl.md (crawl + extraction), skill/scoring.md (formula + weights), skill/report.md (template + compare). Do NOT split further (e.g., one file per reference category).

### Pitfall 8: Staleness Check Fails on macOS Date Parsing
**What goes wrong:** The `date -j -f` flag is macOS-specific. If the script runs on Linux (unlikely for this project but possible), it fails silently.
**Prevention:** Use macOS date syntax since that is the only platform. Add a comment noting the platform dependency.

## Minor Pitfalls

### Pitfall 9: Lighthouse JSON Output is Large (~500KB-1MB)
**What goes wrong:** Passing the full Lighthouse JSON through Claude's context wastes tokens on screenshot data, trace data, and audit details we do not use.
**Prevention:** Use `jq` to extract only needed fields (category scores + CWV metrics) before giving output to Claude. The lighthouse.sh script should return a compact ~200-byte JSON, not the full report.

### Pitfall 10: curl Follows Redirects Differently Than Browsers
**What goes wrong:** `curl -sL` follows HTTP redirects but does not handle JavaScript redirects (`window.location.href = ...`) or meta refresh tags.
**Prevention:** Accept this limitation. Sites using JS redirects are rare in the audit context. If curl returns an HTML page with a meta refresh, treat it as the response.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Lighthouse CLI integration | Score variance between runs | Document margin of error in report |
| curl hybrid crawl | Missing JS-rendered content | Compare curl vs Playwright on homepage first |
| SKILL.md modularization | Over-splitting wastes tool calls | Maximum 3-4 module files |
| Scoring tests | Reference file edits break all fixtures | Update fixtures deliberately after reference changes |
| Stale rule detection | macOS-specific date parsing | Use `date -j -f` syntax, document platform dependency |
| Rule research | Claude proposes bad updates | Always show diff and require user approval |

## Sources

- Lighthouse score variability: observed in testing (example.com scored 100 consistently, but real-world sites vary)
- curl vs Playwright gap: verified by comparing curl output (static HTML) against Playwright extraction on web.dev
- xmllint warnings: observed during web.dev testing (HTML parser errors on `&` in URLs)
- CONCERNS.md: documents existing pitfalls (overwrite, scoring ambiguity, monolith fragility)

---

*Pitfalls research: 2026-03-05*
