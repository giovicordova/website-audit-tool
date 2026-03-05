---
phase: quick-3
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - docs/logs/2026-03-05-log-chapterpass.com.md
  - docs/logs/2026-03-05-log-chapterpass.com-2.md
  - docs/logs/2026-03-05-log-giovannicordova.com.md
  - docs/logs/2026-03-05-log-docs.perplexity.ai.md
  - docs/w-audit/2026-03-05-audit-chapterpass.com.md
  - docs/w-audit/2026-03-05-audit-chapterpass.com-2.md
  - docs/w-audit/2026-03-05-audit-giovannicordova.com.md
  - docs/w-audit/2026-03-05-audit-docs.perplexity.ai.md
  - modules/report-template.md
autonomous: true
requirements: []
must_haves:
  truths:
    - "All log files follow {YYYY-MM-DD}-log-{domain}.md naming"
    - "All audit files follow {YYYY-MM-DD}-audit-{domain}.md naming"
    - "Same-domain same-day collisions use -2, -3 suffix"
    - "No log file contains Lighthouse scores"
    - "session-review.md is removed from docs/logs/"
    - "report-template.md documents the new naming AND full log template"
  artifacts:
    - path: "modules/report-template.md"
      provides: "Updated naming convention and log template"
  key_links:
    - from: "modules/report-template.md"
      to: "docs/logs/"
      via: "naming convention instructions"
---

<objective>
Fix audit log and report naming convention (drop time component), standardize log content template, clean up inconsistent files.

Purpose: Third and final fix to naming convention. User wants `{YYYY-MM-DD}-log-{domain}.md` with collision suffixes, NOT timestamps.
Output: Renamed files, updated report-template.md with naming + log template, clean docs/logs/ directory.
</objective>

<execution_context>
@/Users/giovannicordova/.claude/get-shit-done/workflows/execute-plan.md
@/Users/giovannicordova/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@modules/report-template.md
@docs/logs/2026-03-05-16-43-chapterpass.com.md (best log — use as template basis)
@docs/logs/2026-03-05-17-30-docs.perplexity.ai.md (thin log with Lighthouse — needs fixing)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rename all existing log and audit files, remove session-review, fix perplexity log</name>
  <files>docs/logs/, docs/w-audit/</files>
  <action>
  1. **Rename log files** using `git mv` (preserves history):
     - `2026-03-05-00-00-chapterpass.com.md` -> `2026-03-05-log-chapterpass.com.md`
     - `2026-03-05-16-43-chapterpass.com.md` -> `2026-03-05-log-chapterpass.com-2.md` (collision: second chapterpass log same day)
     - `2026-03-05-00-00-giovannicordova.com.md` -> `2026-03-05-log-giovannicordova.com.md`
     - `2026-03-05-17-30-docs.perplexity.ai.md` -> `2026-03-05-log-docs.perplexity.ai.md`

  2. **Rename audit files** using `git mv`:
     - `2026-03-05-00-00-audit-chapterpass.com.md` -> `2026-03-05-audit-chapterpass.com.md`
     - `2026-03-05-16-43-audit-chapterpass.com.md` -> `2026-03-05-audit-chapterpass.com-2.md` (collision)
     - `2026-03-05-00-00-audit-giovannicordova.com.md` -> `2026-03-05-audit-giovannicordova.com.md`
     - `2026-03-05-17-30-audit-docs.perplexity.ai.md` -> `2026-03-05-audit-docs.perplexity.ai.md`

  3. **Remove session-review.md** from docs/logs/ — it is NOT an audit log. Use `git rm`.

  4. **Fix perplexity log content**: After renaming, edit `2026-03-05-log-docs.perplexity.ai.md`:
     - Remove the entire `## Lighthouse` section (lines with Performance, Accessibility, SEO, Best Practices, LCP/CLS/TBT). Lighthouse data belongs in the audit report only.
     - Restructure to match the standard log format (see Task 2 for template). Specifically:
       - Rename `## Pages Crawled` to `## Crawl Summary` with sub-bullets using `**Pages crawled:**` format
       - Rename `## Checks Run` to `## Check Results Summary` and convert to table format (Passed/Warnings/Failed/N/A/Untestable/Score columns). Use the check counts already present but note scores are in the audit report.
       - Rename `## Technical Files` to be under `## Crawl Summary` as `**Technical files checked:**`
       - Add `## Timing` section with "Not recorded" note
       - Add `## Skill Performance Notes` section with "Not recorded" note
       - Keep `## Errors` as `## Issues During Audit`

  **Ordering note:** The first chapterpass log (00-00) was the earlier audit. The 16-43 one is newer and better quality, so it gets the `-2` suffix. This is chronological order: first file = no suffix, second = `-2`.
  </action>
  <verify>
    <automated>ls docs/logs/ && echo "---" && ls docs/w-audit/ && echo "---" && ! test -f docs/logs/2026-03-05-00-00-session-review.md && echo "session-review removed" && ! grep -l "Lighthouse" docs/logs/*.md && echo "no Lighthouse in logs"</automated>
  </verify>
  <done>All files renamed to new convention, no time component in any filename, collision suffixes applied, session-review removed, perplexity log has no Lighthouse data</done>
</task>

<task type="auto">
  <name>Task 2: Update report-template.md with new naming convention and full log template</name>
  <files>modules/report-template.md</files>
  <action>
  In `modules/report-template.md`, find the audit log instruction on line 80 and replace it with the updated naming convention AND a full log template. The changes:

  1. **Update audit report naming** (line 5): Change `docs/w-audit/{YYYY-MM-DD}-{HH-MM}-audit-{domain}.md` to `docs/w-audit/{YYYY-MM-DD}-audit-{domain}.md`

  2. **Update compare report naming** (line 116): Change `docs/w-audit/{YYYY-MM-DD}-{HH-MM}-compare-{domain1}-vs-{domain2}.md` to `docs/w-audit/{YYYY-MM-DD}-compare-{domain1}-vs-{domain2}.md`

  3. **Replace the audit log line (line 80)** with a full section including naming convention AND template:

  ```
  **Then: save the audit log** to `docs/logs/{YYYY-MM-DD}-log-{domain}.md`.
  Create the `docs/logs/` directory if it doesn't exist.
  If a log already exists for the same domain on the same date, append a collision suffix: `-2`, `-3`, etc. (e.g., `2026-03-05-log-example.com-2.md`).
  Apply the same collision rule to audit reports in `docs/w-audit/`.

  This is the authoritative log — a Stop hook may also generate one, but SKILL.md is the source of truth since hooks are not version-controlled.

  Audit log template:

  ```markdown
  # Audit Log: {domain}
  **Date:** {YYYY-MM-DD}

  ## Crawl Summary
  - **Pages crawled:**
    - {url} -- {status_code}
    - ...
  - **Technical files checked:**
    - robots.txt -- {status_code} ({details})
    - sitemap.xml -- {status_code} ({url_count} URLs)
    - llms.txt -- {status_code}
    - 404 test -- {status_code} ({correct or issue})
  - **Blog post crawled:** {Yes (N posts) | No (reason)}

  ## Issues During Audit
  - {Any problems, errors, workarounds, or "None"}

  ## Check Results Summary
  | Category | Passed | Warnings | Failed | N/A | Untestable | Score |
  |---|---|---|---|---|---|---|
  | AEO | {n} | {n} | {n} | {n} | {n} | {score}/100 |
  | GEO | {n} | {n} | {n} | {n} | {n} | {score}/100 |
  | SEO Technical | {n} | {n} | {n} | {n} | {n} | {score}/100 |
  | SEO On-Page | {n} | {n} | {n} | {n} | {n} | {score}/100 |
  | Structured Data | {n} | {n} | {n} | {n} | {n} | {score}/100 |

  ## Timing
  - Phase A (parallel technical + homepage): ~{N}s
  - Phase B (page discovery): ~{N}s
  - Phase C (sequential page crawl): ~{N}s ({N} pages)
  - Phase D (blog post): ~{N}s | skipped ({reason})
  - Analysis + scoring: ~{N}s
  - Report writing: ~{N}s

  ## Skill Performance Notes

  ### What worked well
  - {observation}

  ### What was slow, failed, or required workarounds
  - {observation or "None"}

  ### Concrete suggestions for SKILL.md improvements
  1. {suggestion}
  ```
  ```

  Do NOT include Lighthouse scores in the log template. Lighthouse data goes in the audit report only.
  </action>
  <verify>
    <automated>grep -c "YYYY-MM-DD.*log.*domain" modules/report-template.md && grep -c "Skill Performance Notes" modules/report-template.md && ! grep "HH-MM" modules/report-template.md && echo "no HH-MM references remain"</automated>
  </verify>
  <done>report-template.md has new naming convention (no time), collision suffix rule, full log template with all 5 sections (Crawl Summary, Issues, Check Results, Timing, Skill Performance Notes), no Lighthouse in log template</done>
</task>

</tasks>

<verification>
- `ls docs/logs/` shows only files matching `{YYYY-MM-DD}-log-{domain}.md` pattern
- `ls docs/w-audit/` shows only files matching `{YYYY-MM-DD}-audit-{domain}.md` pattern
- No file in docs/logs/ contains "Lighthouse"
- session-review.md is gone from docs/logs/
- `grep "HH-MM" modules/report-template.md` returns nothing
- report-template.md contains the full log template with all 5 sections
</verification>

<success_criteria>
- All 9 files renamed (4 logs + 4 audits + 1 removed)
- Perplexity log cleaned (no Lighthouse)
- report-template.md updated with naming convention and log template
- No time component in any filename or naming instruction
</success_criteria>

<output>
After completion, create `.planning/quick/3-fix-audit-log-naming-convention-and-ensu/3-SUMMARY.md`
</output>
