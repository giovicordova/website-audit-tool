# Codebase Concerns

**Analysis Date:** 2026-03-05

## Tech Debt

**JS Extraction Function Uses IIFE But Playwright MCP Requires Arrow Function:**
- Issue: `SKILL.md` section 1.1 (line 68) defines the JS extraction function as an IIFE `(() => {...})()`, but Playwright MCP rejects self-invoking functions and requires `() => {...}` (arrow function without self-invocation). The second audit run (`docs/logs/audit-log-giovannicordova.com-2026-03-05.md`) documents this causing a failed `browser_evaluate` call on the homepage before the syntax was corrected mid-session.
- Files: `SKILL.md` (line 68)
- Impact: Every new audit session risks a wasted tool call on the first page. Claude may or may not remember the workaround from session to session.
- Fix approach: Change `(() => {` on line 68 to `() => {` and remove the closing `})()` on the corresponding closing line. Add a comment: "Pass as arrow function, NOT IIFE -- Playwright MCP rejects self-invoking functions."

**WARNING Scoring Undefined in SKILL.md:**
- Issue: The scoring section (Section 4, lines 199-212) defines PASS = full points and FAIL = 0 points, but never defines how WARNING maps to points. During audits, Claude used half-points for WARNING, but this is improvised -- not specified anywhere.
- Files: `SKILL.md` (Section 4: Score)
- Impact: Scoring inconsistency between audit sessions. Different Claude instances may assign different point values to WARNINGs, making scores non-comparable across runs.
- Fix approach: Add to Section 4: "PASS = full points, WARNING = half points (rounded down), FAIL = 0 points."

**Audit Log Instruction Contradicts Hook System:**
- Issue: `SKILL.md` (line 282) tells Claude to save an audit log to `docs/logs/audit-log-{domain}-{date}.md`. The session review (`docs/logs/2026-03-05-session-review.md`, line 47) says a Stop hook (`stop-summary.sh`) auto-generates this log. The `.gitignore` excludes `.claude/hooks.json` and `.claude/hooks/`, so the hook code is not version-controlled. If the hook works, the SKILL.md instruction creates a duplicate; if the hook doesn't work, the SKILL.md instruction is the only fallback.
- Files: `SKILL.md` (line 282), `.gitignore` (lines 2-3)
- Impact: Potential duplicate log files or confusion about which system is responsible for logging.
- Fix approach: Decide on one source of truth. Recommendation: keep the SKILL.md instruction (it works reliably) and document that the hook is an optional enhancement. Or remove the SKILL.md instruction and version-control the hooks.

**Same-Day Audit Overwrites Previous Report:**
- Issue: Report filenames use `audit-{domain}-{YYYY-MM-DD}.md`. Running two audits of the same domain on the same day overwrites the first report. The giovannicordova.com audit log explicitly notes "Run 2 (overwrote Run 1 report)".
- Files: `SKILL.md` (Section 5: Report, line 227)
- Impact: Loss of audit history when iterating on a site within a single day.
- Fix approach: Append a run number or timestamp to the filename: `audit-{domain}-{YYYY-MM-DD}-{run}.md` or `audit-{domain}-{YYYY-MM-DD}T{HH-MM}.md`.

**PROJECT-BRIEF.md Is Outdated:**
- Issue: `PROJECT-BRIEF.md` describes the tool as a Python Agent SDK application with custom MCP servers, a CLI interface, and a fix-mode loop. The actual implementation is a Claude Code skill with no Python code, no custom MCPs, and no fix mode. The "Build Order" (4 phases) and "Tech Stack" sections describe an architecture that was never built.
- Files: `PROJECT-BRIEF.md`
- Impact: Any Claude instance reading this file for context will get a misleading picture of the project. The design doc (`docs/plans/2026-03-05-website-audit-tool-design.md`) already documents the correct "What We're NOT Building" decisions, but `PROJECT-BRIEF.md` still reflects the original ambitious plan.
- Fix approach: Either rewrite `PROJECT-BRIEF.md` to match reality or add a prominent note at the top: "This was the original proposal. See `docs/plans/2026-03-05-website-audit-tool-design.md` for actual architecture decisions."

## Known Bugs

**`pagespeed.sh` Has No Error Handling for API Response Failures:**
- Symptoms: If the PageSpeed API returns an error JSON (rate limit, invalid URL, server error), the Python parser crashes with a KeyError or prints empty/malformed output.
- Files: `scripts/pagespeed.sh` (lines 20-38)
- Trigger: Run `scripts/pagespeed.sh` with a valid API key but an unreachable domain, or after hitting rate limits.
- Workaround: The SKILL.md instructs Claude to catch the failure and mark checks as UNTESTABLE. But the script itself exits 0 even on API errors, making it hard for Claude to detect failure programmatically.
- Fix: Add error checking in the Python block: check for `error` key in response JSON, exit with code 1 and a clear error message.

**`pagespeed.sh` URL Parameter Not URL-Encoded:**
- Symptoms: URLs with special characters (query params, fragments, non-ASCII) break the curl command.
- Files: `scripts/pagespeed.sh` (line 19)
- Trigger: Pass a URL with `?`, `&`, or `#` characters.
- Workaround: None -- the script only works with clean domain URLs.
- Fix: URL-encode the `$URL` parameter before passing to curl: `URL_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$URL', safe=':/'))")`.

## Security Considerations

**No Secrets Currently Exposed:**
- Risk: Low. The project has no `.env` file committed, no API keys in code. `.gitignore` correctly excludes `.env`.
- Files: `.gitignore`, `scripts/pagespeed.sh`
- Current mitigation: `PAGESPEED_API_KEY` is read from environment variable, not hardcoded. `.env` is gitignored.
- Recommendations: None needed. The current approach is correct.

**Playwright MCP Executes Arbitrary JavaScript on Visited Sites:**
- Risk: The JS extraction function in `SKILL.md` runs `browser_evaluate` on every crawled page. If a malicious site includes JS that modifies the DOM in a way that causes the extraction function to return attacker-controlled data, that data flows into the audit report.
- Files: `SKILL.md` (Section 1.1, lines 67-174)
- Current mitigation: The extraction function only reads DOM properties (querySelectorAll, textContent, getAttribute). It does not execute site JavaScript or interact with page scripts.
- Recommendations: This is acceptable risk for an audit tool. No action needed unless the tool starts making decisions (like "fix mode") based on extracted data.

## Performance Bottlenecks

**Sequential Playwright Crawling Is the Slowest Phase:**
- Problem: Each page takes 5-8 seconds (navigate + evaluate). Crawling 7 pages takes ~60 seconds. This is the dominant cost in every audit.
- Files: `SKILL.md` (Phase C, lines 50-55)
- Cause: Playwright MCP uses a single browser instance. Concurrent navigations cause stale DOM reads (confirmed in first audit run). Sequential crawling is the only reliable approach.
- Improvement path: No fix within Playwright MCP constraints. The only option would be a custom MCP server that manages multiple browser contexts, but that contradicts the "no custom MCPs" design decision. Acceptable as-is for 5-7 pages.

**Large Playwright Snapshots Consume Context:**
- Problem: `browser_navigate` returns a DOM snapshot by default. Some pages (e.g., /reviews) produce 67KB+ snapshots. These consume Claude's context window without being used -- all useful data comes from `browser_evaluate`.
- Files: `SKILL.md` (Phase C)
- Cause: Playwright MCP default behavior returns snapshots on navigation.
- Improvement path: Document in SKILL.md that Claude should not call `browser_snapshot` separately after `browser_navigate`. The navigate snapshot is unavoidable but the evaluate output is what matters. Consider instructing Claude to minimize snapshot processing.

## Fragile Areas

**SKILL.md Is the Entire Application:**
- Files: `SKILL.md` (304 lines)
- Why fragile: The entire audit logic -- crawl strategy, JS extraction, scoring formula, report template, compare mode -- lives in a single 304-line markdown file. A bad edit to one section can break unrelated functionality. There are no tests, no type checking, and no way to validate changes except running a full audit.
- Safe modification: Edit one section at a time. After any change, run a full audit against a known site and compare the report to a previous run.
- Test coverage: Zero automated tests. The only validation is manual: run an audit and check the output.

**Reference Files Have No Versioning or Changelog:**
- Files: `references/aeo.md`, `references/geo.md`, `references/seo-technical.md`, `references/seo-on-page.md`, `references/structured-data.md`
- Why fragile: Each file has "Last reviewed: 2026-03-05" but no changelog. If a check is added, removed, or reworded, there is no record of what changed or why. This matters because scoring depends on the exact number and severity of checks.
- Safe modification: Use git history to track changes. Consider adding a changelog section to each reference file.
- Test coverage: None. Changes to checks directly affect scores with no validation.

**Scoring Formula Is Implicit and Spread Across Multiple Files:**
- Files: `SKILL.md` (Section 4), `references/*.md` (severity headers determine point values)
- Why fragile: The score for a category depends on counting checks under CRITICAL/IMPORTANT/NICE TO HAVE headers in the reference files, then applying the formula in SKILL.md. Adding a single check to a reference file changes the denominator and shifts all scores. There is no way to predict how a reference file edit affects scoring without manually counting.
- Safe modification: After editing any reference file, count checks by severity and verify the maximum possible score per category.
- Test coverage: None.

## Scaling Limits

**Page Crawl Limit:**
- Current capacity: Homepage + 5 most-linked pages + 1 blog post = 7 pages per audit.
- Limit: Claude's context window. Each page produces ~2-5KB of extracted data plus the unavoidable Playwright snapshot. At ~10KB per page (data + snapshot), 20+ pages would start crowding the context window for analysis.
- Scaling path: For larger sites, implement a sampling strategy (e.g., one page per template/layout type instead of most-linked pages). Not needed now.

**Single-Domain Audits Only:**
- Current capacity: One domain at a time (compare mode runs sequentially).
- Limit: Compare mode with 3+ sites takes 3x the time and context. Four sites would likely exhaust the context window.
- Scaling path: Not a priority. Two-site comparisons work fine.

## Dependencies at Risk

**Playwright MCP Dependency:**
- Risk: The entire crawl phase depends on Playwright MCP being available and configured in Claude Code. If Playwright MCP changes its API (e.g., the `browser_evaluate` function signature), every audit breaks.
- Impact: Total crawl failure -- no audit possible.
- Migration plan: Could fall back to `curl` for basic HTML fetching, but would lose JavaScript-rendered content. No good alternative exists within Claude Code's tool ecosystem.

**PageSpeed Insights API (Free Tier):**
- Risk: Google's free tier has rate limits (documented as "400 requests per day"). Heavy usage or API changes could break Core Web Vitals checking.
- Impact: 4 checks become UNTESTABLE (already the case when the key is not set). Audit still completes.
- Migration plan: The v2 improvements doc suggests `npx lighthouse --output=json --chrome-flags="--headless"` as a local fallback. This has not been implemented.

## Missing Critical Features

**No Automated Validation:**
- Problem: There is no way to verify that an audit produces correct results. No test suite, no golden-file comparisons, no regression checks.
- Blocks: Confident refactoring of SKILL.md, reference files, or scoring logic. Every change requires a manual audit run to validate.

**No PageSpeed API Key Set Up:**
- Problem: `PAGESPEED_API_KEY` is not configured in the environment. 4 checks (Core Web Vitals, Lighthouse performance, Lighthouse accessibility, page load time) are permanently UNTESTABLE.
- Blocks: Complete SEO Technical scoring. Every audit reports "100/100" for SEO Technical because the hardest checks are excluded from the denominator.

**Fix Mode Not Implemented:**
- Problem: `PROJECT-BRIEF.md` describes a "fix mode" where the tool edits the codebase and re-audits. The design doc (`docs/plans/2026-03-05-website-audit-tool-design.md`, line 111) explicitly deferred this: "No fix mode (user fixes from the report using existing skills)."
- Blocks: The original value proposition of "tells you AND fixes it."

## Test Coverage Gaps

**Zero Automated Tests:**
- What's not tested: Everything. There are no test files in the repository.
- Files: Entire codebase
- Risk: Any edit to `SKILL.md`, reference files, or `scripts/pagespeed.sh` could introduce regressions with no detection mechanism.
- Priority: Medium. The codebase is small (495 total lines across all files) and changes are infrequent. Manual validation after each change is sufficient for now, but becomes unsustainable if the tool grows.

**No Scoring Regression Tests:**
- What's not tested: The scoring formula and its interaction with check counts in reference files.
- Files: `SKILL.md` (Section 4), `references/*.md`
- Risk: Adding or removing a check changes all scores for that category. No way to detect unintended score drift.
- Priority: High. This is the most likely source of silent regressions when reference files are updated.

**No Report Format Validation:**
- What's not tested: Whether the generated report matches the template structure in `SKILL.md`.
- Files: `SKILL.md` (Section 5), `docs/w-audit/*.md`
- Risk: Claude may deviate from the template (add sections, skip sections, change formatting) with no detection.
- Priority: Low. The two existing reports both match the template closely.

---

*Concerns audit: 2026-03-05*
