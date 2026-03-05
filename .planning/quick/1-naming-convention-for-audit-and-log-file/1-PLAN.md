---
phase: quick
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - docs/w-audit/2026-03-05-00-00-audit-chapterpass.com.md
  - docs/w-audit/2026-03-05-16-43-audit-chapterpass.com.md
  - docs/w-audit/2026-03-05-00-00-audit-giovannicordova.com.md
  - modules/report-template.md
  - SKILL.md
autonomous: true
requirements: [NAMING-01]
must_haves:
  truths:
    - "All audit files in docs/w-audit/ follow YYYY-MM-DD-HH-MM-audit-domain.md pattern"
    - "All log files in docs/logs/ follow YYYY-MM-DD-HH-MM-domain.md pattern"
    - "SKILL.md and report-template.md produce correctly named files for future audits"
  artifacts:
    - path: "docs/w-audit/2026-03-05-00-00-audit-chapterpass.com.md"
      provides: "Renamed audit file"
    - path: "docs/w-audit/2026-03-05-16-43-audit-chapterpass.com.md"
      provides: "Renamed audit file"
    - path: "docs/w-audit/2026-03-05-00-00-audit-giovannicordova.com.md"
      provides: "Renamed audit file"
    - path: "modules/report-template.md"
      provides: "Updated naming instructions for audits, logs, and compare reports"
    - path: "SKILL.md"
      provides: "No naming instructions in SKILL.md (all in report-template.md)"
  key_links:
    - from: "modules/report-template.md"
      to: "docs/w-audit/"
      via: "File naming pattern in save instructions"
      pattern: "YYYY-MM-DD-HH-MM-audit-"
---

<objective>
Enforce a consistent naming convention for all audit, log, and compare files.

Purpose: Current audit files use mixed formats (some have `T` separators, some lack timestamps). Standardize to `YYYY-MM-DD-HH-MM-audit-domain.md` for audits, `YYYY-MM-DD-HH-MM-domain.md` for logs, and `YYYY-MM-DD-HH-MM-compare-domainA-vs-domainB.md` for comparisons.

Output: Renamed existing audit files + updated report-template.md so future audits produce correctly named files.
</objective>

<execution_context>
@/Users/giovannicordova/.claude/get-shit-done/workflows/execute-plan.md
@/Users/giovannicordova/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@modules/report-template.md
@SKILL.md

Current audit files (need renaming):
- `docs/w-audit/audit-chapterpass.com-2026-03-05.md` -> `docs/w-audit/2026-03-05-00-00-audit-chapterpass.com.md`
- `docs/w-audit/audit-chapterpass.com-2026-03-05T16-43.md` -> `docs/w-audit/2026-03-05-16-43-audit-chapterpass.com.md`
- `docs/w-audit/audit-giovannicordova.com-2026-03-05.md` -> `docs/w-audit/2026-03-05-00-00-audit-giovannicordova.com.md`

Log files already follow convention (renamed earlier this session):
- `docs/logs/2026-03-05-00-00-chapterpass.com.md` (OK)
- `docs/logs/2026-03-05-00-00-giovannicordova.com.md` (OK)
- `docs/logs/2026-03-05-00-00-session-review.md` (OK)
- `docs/logs/2026-03-05-16-43-chapterpass.com.md` (OK)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rename existing audit files to new convention</name>
  <files>docs/w-audit/</files>
  <action>
Rename the three existing audit files using `git mv`:

1. `git mv docs/w-audit/audit-chapterpass.com-2026-03-05.md docs/w-audit/2026-03-05-00-00-audit-chapterpass.com.md`
2. `git mv docs/w-audit/audit-chapterpass.com-2026-03-05T16-43.md docs/w-audit/2026-03-05-16-43-audit-chapterpass.com.md`
3. `git mv docs/w-audit/audit-giovannicordova.com-2026-03-05.md docs/w-audit/2026-03-05-00-00-audit-giovannicordova.com.md`

Pattern: date-first (`YYYY-MM-DD-HH-MM`), then type (`audit`), then domain. Files that had no timestamp get `00-00`. Files that had `T16-43` get `16-43` (drop the T).

After renaming, verify no old-named files remain in `docs/w-audit/`.
  </action>
  <verify>
    <automated>ls docs/w-audit/*.md | grep -c "^docs/w-audit/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}-" | grep -q "3" && echo "PASS: all 3 files renamed" || echo "FAIL"</automated>
  </verify>
  <done>All audit files in docs/w-audit/ follow YYYY-MM-DD-HH-MM-audit-domain.md pattern. No old-format files remain.</done>
</task>

<task type="auto">
  <name>Task 2: Update report-template.md with new naming convention</name>
  <files>modules/report-template.md</files>
  <action>
Update the three file-saving instructions in `modules/report-template.md`:

1. **Audit report** (line 5, currently `docs/w-audit/audit-{domain}-{YYYY-MM-DD}T{HH-MM}.md`):
   Change to: `docs/w-audit/{YYYY-MM-DD}-{HH-MM}-audit-{domain}.md`

2. **Audit log** (line 80, currently `docs/logs/audit-log-{domain}-{YYYY-MM-DD}T{HH-MM}.md`):
   Change to: `docs/logs/{YYYY-MM-DD}-{HH-MM}-{domain}.md`
   Note: drop the `audit-log-` prefix. Logs use just `YYYY-MM-DD-HH-MM-domain.md`.

3. **Compare report** (line 116, currently `docs/w-audit/compare-{domain1}-vs-{domain2}-{YYYY-MM-DD}T{HH-MM}.md`):
   Change to: `docs/w-audit/{YYYY-MM-DD}-{HH-MM}-compare-{domain1}-vs-{domain2}.md`

Pattern for all three: date comes first, then descriptive type, then domain(s). Hyphens as separators (no `T`).

Do NOT change any other content in the file. Only update the filename patterns in these three save-to instructions.
  </action>
  <verify>
    <automated>grep -c "YYYY-MM-DD}-{HH-MM}" modules/report-template.md | grep -q "3" && echo "PASS: 3 date-first patterns found" || echo "FAIL"</automated>
  </verify>
  <done>report-template.md uses date-first naming convention for all three output file types (audit, log, compare). No T separators. No domain-first patterns remain.</done>
</task>

</tasks>

<verification>
1. `ls docs/w-audit/` shows only files matching `YYYY-MM-DD-HH-MM-audit-*.md` or `YYYY-MM-DD-HH-MM-compare-*.md`
2. `ls docs/logs/` shows only files matching `YYYY-MM-DD-HH-MM-*.md`
3. `grep` report-template.md for old patterns (`audit-{domain}-{YYYY`, `audit-log-{domain}`, `compare-{domain1}-vs-{domain2}-{YYYY`) returns zero matches
</verification>

<success_criteria>
- All existing audit files renamed to date-first convention
- report-template.md updated so future audits produce correctly named files
- Log files already correct (no changes needed)
- Git history preserved via `git mv`
</success_criteria>

<output>
After completion, create `.planning/quick/1-naming-convention-for-audit-and-log-file/1-SUMMARY.md`
</output>
