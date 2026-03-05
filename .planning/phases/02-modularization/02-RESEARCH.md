# Phase 2: Modularization - Research

**Researched:** 2026-03-05
**Domain:** Claude Code skill file restructuring (markdown-based instruction modules)
**Confidence:** HIGH

## Summary

This phase splits a 306-line SKILL.md (a Claude Code skill file written in markdown) into focused modules. The two largest extractable blocks are the JS extraction function (~110 lines, Section 1.1) and the report template (~50 lines, Section 5). After extraction, SKILL.md becomes an orchestrator that references these external files.

This is NOT traditional code modularization. SKILL.md is a markdown file that Claude reads as instructions. "Modules" are separate files that SKILL.md tells Claude to load during execution. The critical constraint: Claude must produce identical audit output after restructuring. The Phase 1 scoring tests are the safety net.

**Primary recommendation:** Extract JS function to `modules/extraction.js`, report template to `modules/report-template.md`, update SKILL.md to reference both files with explicit "read this file" instructions. Scoring formula stays inline in SKILL.md per MODU-03.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MODU-01 | JS extraction function extracted to a separate file (extraction.js) | Section 1.1 of SKILL.md is a self-contained ~110 line JS block. Extract verbatim to `modules/extraction.js`. SKILL.md replaces inline code with "Read `modules/extraction.js` and use that function." |
| MODU-02 | Report template extracted to a separate file | Section 5 report template is a self-contained markdown block (~50 lines). Extract to `modules/report-template.md`. SKILL.md replaces inline template with "Read `modules/report-template.md` for the report format." |
| MODU-03 | Scoring formula stays in main SKILL.md | Section 4 scoring logic is ~20 lines and tightly coupled to the audit flow (category weights, grade thresholds, N/A handling). Extracting it would split context Claude needs during scoring. Keep inline. |
| MODU-04 | SKILL.md reduced to orchestration-only (~150 lines) | Current: 306 lines. JS function removal saves ~110 lines. Report template removal saves ~50 lines. Result: ~146 lines of orchestration + scoring + compare mode. |
</phase_requirements>

## Architecture Patterns

### Current SKILL.md Structure (306 lines)
```
Lines 1-9:     YAML frontmatter (skill metadata)
Lines 10-21:   Request parsing instructions
Lines 22-175:  Audit flow (crawl phases A-D, JS extraction function)
Lines 176-221: Scoring formula (Section 4)
Lines 222-284: Report template (Section 5)
Lines 285-306: Compare mode
```

### Target Structure After Modularization
```
SKILL.md                    (~150 lines) - orchestration only
modules/
  extraction.js             (~110 lines) - JS extraction function
  report-template.md        (~50 lines)  - report markdown template
references/                 (unchanged)  - scoring reference files
scripts/                    (unchanged)  - lighthouse.sh, score.py
tests/                      (unchanged)  - scoring tests
```

### Pattern: File Reference in SKILL.md

When SKILL.md needs Claude to use an extracted module, the instruction pattern is:

```markdown
#### 1.1 JS Extraction Function

Read `modules/extraction.js` from this skill's directory. Use that exact function
(or a superset of it) for every page via `browser_evaluate`. Do not extract
metadata piecemeal across multiple calls.
```

This works because Claude Code skills already use this pattern for the `references/` directory (see Section 2 of current SKILL.md: "Read the reference files for the requested categories from this skill's `references/` directory").

### Pattern: Report Template Reference

```markdown
### 5. Report

Read `modules/report-template.md` from this skill's directory. Fill in all
{placeholders} with actual audit data. Follow the exact format -- do not
improvise sections or reorder categories.
```

### Anti-Patterns to Avoid

- **Extracting the scoring formula:** MODU-03 explicitly keeps it inline. The scoring formula is 20 lines and needs to be visible during the audit flow so Claude applies it correctly. Extracting it would force Claude to context-switch between files mid-scoring.
- **Creating a `modules/crawl.md` for crawl instructions:** The crawl phases (A-D) are orchestration logic -- they describe WHEN and HOW to crawl, which is SKILL.md's core job. Only the JS function (WHAT to extract) is separable.
- **Splitting compare mode into its own file:** Compare mode is ~20 lines and tightly coupled to the scoring/report flow. Not worth a separate file.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Module loading | Custom include/import system | Direct "Read file X" instructions in SKILL.md | Claude Code already supports reading skill-relative files (see `references/` pattern) |
| Template engine | Placeholder substitution logic | Claude's natural language understanding of {placeholder} patterns | Claude already fills in templates -- no code needed |
| Test for report format | Complex report parser | Visual diff of a test audit before/after | Report output is markdown text, not structured data |

## Common Pitfalls

### Pitfall 1: Breaking the JS Function During Extraction
**What goes wrong:** Copy-paste error, missing closing brace, or adding IIFE wrapper that Playwright MCP rejects.
**Why it happens:** The JS function is an arrow function (not IIFE) because Playwright MCP rejects self-invoking functions. This constraint is noted inline in SKILL.md.
**How to avoid:** Copy the function verbatim. Keep the comment about arrow function requirement in the extracted file. Test with a real `browser_evaluate` call after extraction.
**Warning signs:** Playwright errors about "Cannot evaluate expression" or "Unexpected token."

### Pitfall 2: SKILL.md File Path References
**What goes wrong:** SKILL.md says "read modules/extraction.js" but Claude can't find it because the path is relative to the wrong directory.
**Why it happens:** Claude Code skill files use paths relative to the skill's root directory (where SKILL.md lives). If the instruction says `modules/extraction.js` without anchoring to "this skill's directory," Claude may look in the wrong place.
**How to avoid:** Use the same phrasing as the existing `references/` pattern: "from this skill's `modules/` directory."

### Pitfall 3: Report Template Losing Formatting Details
**What goes wrong:** The extracted report template loses emoji markers (red/yellow/green circles), heading levels, or the exact field order.
**Why it happens:** When copying markdown into a separate file, it's easy to miss that the circles and field order are part of the specification.
**How to avoid:** Extract the ENTIRE Section 5 block including all formatting notes, emoji references, and ordering instructions.

### Pitfall 4: Scoring Tests Don't Cover Report Output
**What goes wrong:** Scoring tests pass but the report format changed subtly (missing section, wrong heading level).
**Why it happens:** Phase 1 tests only validate score calculation (score.py), not report structure.
**How to avoid:** After extraction, run a manual comparison: audit the same test URL before and after, diff the reports. This is a one-time verification, not an automated test.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash test scripts (no framework, custom assert_eq) |
| Config file | None -- tests are standalone bash scripts |
| Quick run command | `bash tests/test-scoring.sh` |
| Full suite command | `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MODU-01 | JS extraction function in separate file | smoke | `test -f modules/extraction.js && echo PASS` | Will be created |
| MODU-02 | Report template in separate file | smoke | `test -f modules/report-template.md && echo PASS` | Will be created |
| MODU-03 | Scoring formula stays in SKILL.md | grep | `grep -q "Critical checks: 3 points" SKILL.md && echo PASS` | SKILL.md exists |
| MODU-04 | SKILL.md under 150 lines | count | `[ $(wc -l < SKILL.md) -le 150 ] && echo PASS` | SKILL.md exists |
| REGRESSION | Scoring tests still pass after restructuring | unit | `bash tests/test-scoring.sh` | Yes |
| REGRESSION | Lighthouse tests still pass after restructuring | unit | `bash tests/test-lighthouse-output.sh` | Yes |

### Sampling Rate
- **Per task commit:** `bash tests/test-scoring.sh`
- **Per wave merge:** `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh`
- **Phase gate:** Full suite green + SKILL.md line count <= 150 + both module files exist

### Wave 0 Gaps
None -- existing test infrastructure covers all regression requirements. New module files are verified by existence checks, not test scripts.

## Code Examples

### Extracted extraction.js File
The file should contain the exact function from SKILL.md Section 1.1 (lines 69-175), wrapped with a comment header:

```javascript
// JS Extraction Function for Website Audit Skill
// Used by SKILL.md via browser_evaluate on every crawled page.
// IMPORTANT: This MUST be an arrow function, NOT an IIFE.
// Playwright MCP rejects self-invoking functions.

() => {
  // ... exact contents of current Section 1.1 ...
}
```

### Extracted report-template.md File
The file should contain the exact template from SKILL.md Section 5 (lines 227-283), including:
- The conversational summary instruction
- The file path pattern (`docs/w-audit/audit-{domain}-{YYYY-MM-DD}T{HH-MM}.md`)
- The full markdown template with all placeholders
- The fix priority list ordering rules
- The audit log instruction

### Updated SKILL.md Reference Pattern
Replace inline JS function with:
```markdown
#### 1.1 JS Extraction Function

Read `modules/extraction.js` from this skill's directory. Run this exact function
(or a superset of it) via a single `browser_evaluate` call on every page.
Do not extract metadata piecemeal across multiple calls.

**IMPORTANT:** The function must be an arrow function, NOT an IIFE -- Playwright
MCP rejects self-invoking functions.
```

## Open Questions

1. **Compare mode report template**
   - What we know: Compare mode (Section at end of SKILL.md) has its own mini-template (comparison table format). It's ~20 lines.
   - What's unclear: Should the compare table template go into `report-template.md` alongside the main template, or stay inline?
   - Recommendation: Include it in `report-template.md` since it's report formatting. This keeps ALL output formatting in one place.

## Sources

### Primary (HIGH confidence)
- Direct analysis of SKILL.md (306 lines, in project root)
- Direct analysis of scripts/score.py, scripts/lighthouse.sh
- Direct analysis of tests/test-scoring.sh, tests/test-lighthouse-output.sh
- REQUIREMENTS.md (MODU-01 through MODU-04 definitions)
- STATE.md (decision: "Scoring formula stays in SKILL.md during modularization")

### Secondary (MEDIUM confidence)
- Claude Code skill file conventions (based on existing `references/` directory pattern in SKILL.md)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new libraries, pure file restructuring
- Architecture: HIGH - extracting clearly bounded sections from existing file
- Pitfalls: HIGH - based on direct analysis of current code and known constraints (Playwright arrow function requirement, file path patterns)

**Research date:** 2026-03-05
**Valid until:** Indefinite (structural refactoring, not version-dependent)
