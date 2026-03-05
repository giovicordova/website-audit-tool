# Phase 4: Feature Polish - Research

**Researched:** 2026-03-05
**Domain:** AI crawler policy analysis, reference file staleness detection, compare mode simplification
**Confidence:** HIGH

## Summary

Phase 4 covers three independent feature areas that all modify how the audit skill behaves: (1) a new AI Crawler Policy section in the report that grades robots.txt strategy for AI bots, (2) a staleness warning system for reference files older than 90 days, and (3) simplifying compare mode to output only a score-comparison table instead of full side-by-side category reports.

All three features operate on existing infrastructure. The AI crawler policy analysis uses the robots.txt content already fetched in Phase A (curl). Staleness detection reads the `Last reviewed:` date already present in every reference file. Compare mode simplification removes content from the existing report template rather than adding new capability.

**Primary recommendation:** Implement all three as edits to existing files (SKILL.md, report-template.md, and possibly a new AI crawler reference list). No new scripts, no new dependencies.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AICR-01 | Grade robots.txt AI bot strategy (distinguish training bots vs retrieval bots) | Comprehensive AI bot list with training/retrieval classification documented below. Grading rubric defined. |
| AICR-02 | Report which AI bots are allowed, blocked, or unaddressed | Bot list with 14 major bots across 6 providers. Parse robots.txt User-agent/Disallow rules per bot. |
| AICR-03 | Provide actionable recommendation for AI crawler policy | Decision framework documented: block training + allow retrieval is the recommended default. |
| RULE-01 | Detect stale reference files (>90 days since last review) | All 5 reference files already have `Last reviewed: YYYY-MM-DD` on line 5. Parse with date comparison. |
| RULE-02 | Warn user at audit start when rules are stale, suggest running update | Add a check at the start of the audit flow (after reading reference files) that compares dates. |
| COMP-01 | Simplified compare mode outputs score-comparison table only | Current compare mode already has the table format. Remove the "full individual audits" section. |
| COMP-02 | Drop full side-by-side category reports from compare output | Edit report-template.md Compare Mode section to output table + analysis only. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| curl | system | Fetch robots.txt (already in Phase A) | Already used, zero new dependencies |
| bash date | system | Compare reference file dates for staleness | No external tools needed |
| SKILL.md | N/A | Orchestration edits for all 3 features | This IS the application |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| modules/report-template.md | N/A | Report format changes (AI section + compare simplification) | Editing report output |
| references/ | N/A | Staleness date source | Reading `Last reviewed:` lines |

### Alternatives Considered
None. All three features are edits to existing files using existing tools.

**Installation:**
```bash
# No new installations needed
```

## Architecture Patterns

### Where Each Feature Lives

```
SKILL.md
  Phase A additions:
    - Parse robots.txt for AI bot rules (AICR-01, AICR-02)
    - After loading reference files, check staleness dates (RULE-01, RULE-02)
  Section 5 changes:
    - Compare mode simplified (COMP-01, COMP-02)

modules/report-template.md
  New section:
    - AI Crawler Policy section in report template (AICR-01, AICR-02, AICR-03)
  Modified section:
    - Compare Mode: table + analysis only, no individual reports (COMP-01, COMP-02)
```

### Pattern 1: AI Crawler Policy Analysis

**What:** Parse robots.txt content (already fetched) to classify each known AI bot as Allowed, Blocked, or Unaddressed. Grade the overall strategy.

**How it works:**
1. Define a canonical list of AI bots with their type (training vs retrieval)
2. Parse robots.txt for `User-agent:` and `Disallow:` directives matching each bot
3. Classify each bot: Blocked (has `Disallow: /`), Allowed (no block or explicit `Allow`), Unaddressed (not mentioned)
4. Grade the strategy based on coverage and intentionality

**AI Bot Canonical List (14 major bots, 6 providers):**

| Provider | Bot Name | Type | Purpose |
|----------|----------|------|---------|
| OpenAI | GPTBot | Training | Collects data for model training |
| OpenAI | OAI-SearchBot | Retrieval | Real-time search indexing |
| OpenAI | ChatGPT-User | Retrieval | Fetches pages during conversations |
| Anthropic | ClaudeBot | Training | Collects data for Claude training |
| Anthropic | Claude-SearchBot | Retrieval | Indexes content for search |
| Anthropic | Claude-User | Retrieval | Fetches pages during conversations |
| Google | Google-Extended | Training | Training data for Gemini/Bard |
| Google | GoogleOther | Training | Additional Google AI training |
| Perplexity | PerplexityBot | Retrieval | Indexes for answer engine |
| Perplexity | Perplexity-User | Retrieval | Real-time page fetching |
| Apple | Applebot-Extended | Training | Extended Apple AI training |
| Meta | Meta-ExternalAgent | Training | Meta AI training data |
| Amazon | Amazonbot | Retrieval | Alexa/Amazon search |
| ByteDance | Bytespider | Training | TikTok/ByteDance AI training |

**Grading Rubric:**

| Grade | Criteria |
|-------|----------|
| A | Intentional strategy: training bots blocked, retrieval bots allowed, no major bots unaddressed |
| B | Mostly intentional: most bots addressed, minor gaps (1-2 unaddressed) |
| C | Partial strategy: some bots addressed but significant gaps or inconsistencies |
| D | Minimal: only 1-2 bots addressed, most unaddressed |
| F | No AI bot rules in robots.txt at all |

**Source:** [ai-robots-txt/ai.robots.txt](https://github.com/ai-robots-txt/ai.robots.txt/blob/main/robots.txt), [Search Engine Journal](https://www.searchenginejournal.com/anthropics-claude-bots-make-robots-txt-decisions-more-granular/568253/), [robotstxt.com/ai](https://robotstxt.com/ai)

### Pattern 2: Reference File Staleness Detection

**What:** At audit start, after loading reference files, check each file's `Last reviewed:` date. If any file is >90 days old, warn the user before proceeding.

**How it works:**
1. Each reference file has `Last reviewed: YYYY-MM-DD` on line 5 (confirmed in all 5 files)
2. Parse the date from each file
3. Compare against current date
4. If any are stale, print a warning listing which files and how old they are
5. Suggest: "Run `update rules` to refresh against official sources"

**Implementation approach:** This is a natural-language instruction in SKILL.md, not a script. Claude reads the dates when it loads the reference files and does the math. No new files needed.

### Pattern 3: Compare Mode Simplification

**What:** Compare mode currently outputs a comparison table PLUS full individual audit reports for each site. Change it to output ONLY the comparison table + 2-3 sentence analysis.

**Current behavior (from report-template.md):**
1. Score-comparison table
2. 2-3 sentence analysis
3. Full individual audit reports for each site (this gets dropped)
4. Saved to `docs/w-audit/compare-{domain1}-vs-{domain2}-{date}.md`

**New behavior:**
1. Score-comparison table
2. 2-3 sentence analysis
3. Per-site "top 3 fixes" summary (keeps it actionable without full reports)
4. Saved to same location

**Key consideration:** Individual site audits are still run (needed to generate scores). The change is only in what gets saved to the comparison report file. Users can still run individual audits separately if they want full category breakdowns.

### Anti-Patterns to Avoid
- **Don't create a new AI crawler reference file**: The bot list belongs in SKILL.md instructions, not as a scored reference category. AI crawler policy is a site-level assessment, not a per-page check.
- **Don't use file modification dates for staleness**: Use the `Last reviewed:` line inside the file, not filesystem mtime. Git operations change mtime.
- **Don't remove individual audit execution from compare mode**: The audits still need to run to generate scores. Only the output format changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| robots.txt parsing | Custom regex parser | Claude's natural language understanding of the already-fetched robots.txt text | robots.txt is simple enough that Claude reading it directly is more reliable than a parser script |
| Date comparison | Python/bash date script | Claude doing date math inline | Only 5 files, comparison is trivial, no edge cases |
| AI bot list maintenance | Hardcoded list in a script | Canonical list in SKILL.md instructions | List changes as new bots appear; natural language is easier to update than code |

**Key insight:** This phase's features are all about changing Claude's behavior through instruction edits, not about writing new code. The tool's architecture (skill-based, markdown-driven) means these features are instruction changes, not code changes.

## Common Pitfalls

### Pitfall 1: AI Bot List Goes Stale
**What goes wrong:** The canonical bot list misses new AI crawlers that launch after the list was written.
**Why it happens:** AI companies launch new bots frequently (Anthropic added Claude-SearchBot and Claude-User in late 2025).
**How to avoid:** Include a note in the SKILL.md instructions that says "also check for any User-agent entries containing 'AI', 'bot', 'crawler', 'spider' that aren't in the canonical list."
**Warning signs:** Audit reports consistently show 0 "unaddressed" bots even for sites with minimal robots.txt.

### Pitfall 2: Staleness Warning Blocks the Audit
**What goes wrong:** The staleness check interrupts the flow, user has to dismiss it, or worse -- the audit stops waiting for user action.
**Why it happens:** Making the warning interactive (yes/no to continue) adds friction.
**How to avoid:** Make it informational only. Print the warning, then proceed with the audit. Don't ask for confirmation.
**Warning signs:** User complaints about extra steps before audits run.

### Pitfall 3: Compare Mode Loses Actionability
**What goes wrong:** The simplified compare report shows scores but gives no guidance on what to fix.
**Why it happens:** Dropping full category reports removes the detail.
**How to avoid:** Keep a "top 3 fixes per site" summary below the comparison table. This gives enough actionability without the full breakdown.
**Warning signs:** Users running individual audits immediately after every comparison.

### Pitfall 4: Robots.txt Wildcard Rules Misinterpreted
**What goes wrong:** A `User-agent: *` with `Disallow: /` is interpreted as blocking AI bots, but a specific `Allow` for an AI bot overrides it.
**Why it happens:** robots.txt precedence rules: specific User-agent blocks override wildcard blocks.
**How to avoid:** Process specific User-agent rules first, then fall back to wildcard rules. A bot with its own `User-agent` section is governed by that section, not by `*`.
**Warning signs:** Sites with `User-agent: *` / `Disallow: /` but specific AI bot allows being graded as "blocking all AI bots."

## Code Examples

### AI Crawler Policy Report Section

```markdown
## AI Crawler Policy

**Strategy Grade: B** — Mostly intentional, 2 bots unaddressed

### Training Bots
| Bot | Provider | Status |
|-----|----------|--------|
| GPTBot | OpenAI | Blocked |
| ClaudeBot | Anthropic | Blocked |
| Google-Extended | Google | Allowed |
| Bytespider | ByteDance | Blocked |
| Meta-ExternalAgent | Meta | Unaddressed |
| Applebot-Extended | Apple | Unaddressed |
| GoogleOther | Google | Allowed |

### Retrieval Bots
| Bot | Provider | Status |
|-----|----------|--------|
| OAI-SearchBot | OpenAI | Allowed |
| ChatGPT-User | OpenAI | Allowed |
| Claude-SearchBot | Anthropic | Allowed |
| Claude-User | Anthropic | Allowed |
| PerplexityBot | Perplexity | Allowed |
| Perplexity-User | Perplexity | Allowed |
| Amazonbot | Amazon | Allowed |

### Recommendation
Block training bots (GPTBot, ClaudeBot, Google-Extended, Bytespider, Meta-ExternalAgent, Applebot-Extended) to protect content from being used in model training. Allow retrieval bots (ChatGPT-User, OAI-SearchBot, Claude-SearchBot, PerplexityBot) so your site appears in AI-powered search results. Currently missing rules for: Meta-ExternalAgent, Applebot-Extended.
```

### Staleness Warning Output

```
Warning: 2 reference files are stale (>90 days since last review):
  - references/aeo.md — last reviewed 2025-11-15 (112 days ago)
  - references/geo.md — last reviewed 2025-10-28 (130 days ago)

Audit results may not reflect current best practices.
Suggestion: run "update rules" to refresh against official sources.

Proceeding with audit...
```

### Simplified Compare Mode Output

```markdown
# Site Comparison: site-a.com vs site-b.com
**Date:** 2026-03-05 | **Sites compared:** 2

## Score Comparison

| Category | site-a.com | site-b.com |
|---|---|---|
| AEO | 70/100 | 85/100 |
| GEO | 65/100 | 90/100 |
| SEO Technical | 95/100 | 80/100 |
| SEO On-Page | 88/100 | 75/100 |
| Structured Data | 75/100 | 60/100 |
| **Overall** | **B+ (80)** | **B+ (82)** |

## Analysis
site-b.com edges ahead overall (82 vs 80), driven by significantly stronger AEO and GEO scores. site-a.com dominates in technical SEO and on-page optimization. The biggest gap is GEO (25-point difference) — site-a.com needs author attribution and source citations.

## Top Fixes Per Site

**site-a.com:**
1. Add author bylines and credentials to content pages (GEO)
2. Add outbound links to authoritative sources (GEO)
3. Add FAQ schema to product pages (AEO)

**site-b.com:**
1. Fix redirect chain on /old-page (SEO Technical)
2. Add unique meta descriptions to blog posts (SEO On-Page)
3. Add Organization schema (Structured Data)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Block all AI bots | Block training, allow retrieval | Late 2025 | Sites that block all AI bots disappear from AI search results |
| Single bot per company | 2-3 bots per company (training/search/user) | 2025 | robots.txt needs per-bot rules, not per-company |
| robots.txt only | robots.txt + llms.txt | 2024-2025 | llms.txt tells AI where your best content is (already checked in SEO Technical) |

**Key shift:** The AI crawler landscape moved from "block or allow OpenAI" to a nuanced 3-tier system (training/search/user) across 6+ major providers. A site's robots.txt strategy now requires 10-14 specific User-agent rules to be comprehensive.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash test scripts (no formal framework) |
| Config file | none |
| Quick run command | `bash tests/test-scoring.sh` |
| Full suite command | `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AICR-01 | AI bot grading produces correct grade for sample robots.txt | unit | `bash tests/test-ai-crawler-grading.sh` | No — Wave 0 |
| AICR-02 | Bot classification (allowed/blocked/unaddressed) is correct | unit | `bash tests/test-ai-crawler-grading.sh` | No — Wave 0 |
| AICR-03 | Recommendation text generated | manual-only | Manual audit run | N/A — natural language output |
| RULE-01 | Staleness detection flags files >90 days old | unit | `bash tests/test-staleness-check.sh` | No — Wave 0 |
| RULE-02 | Warning message displayed at audit start | manual-only | Manual audit run | N/A — Claude behavior |
| COMP-01 | Compare output contains only table + analysis + top fixes | manual-only | Manual compare run | N/A — Claude behavior |
| COMP-02 | Compare output does NOT contain full category reports | manual-only | Manual compare run | N/A — Claude behavior |

### Sampling Rate
- **Per task commit:** `bash tests/test-scoring.sh` (verify no scoring regressions)
- **Per wave merge:** `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh`
- **Phase gate:** Full suite green + one manual audit run to verify AI crawler section appears

### Wave 0 Gaps
- [ ] `tests/test-ai-crawler-grading.sh` -- tests robots.txt parsing against sample inputs (covers AICR-01, AICR-02)
- [ ] `tests/test-staleness-check.sh` -- tests date comparison logic (covers RULE-01)
- [ ] `tests/fixtures/robots-*.txt` -- sample robots.txt files (full coverage, partial, none)

**Note:** AICR-03, RULE-02, COMP-01, COMP-02 are instruction changes to SKILL.md/report-template.md. They produce natural language output interpreted by Claude. The only practical validation is a manual audit run. Automated testing of these would require mocking Claude's execution, which is out of scope.

**Practical concern:** Since this is a Claude Code skill (not compiled code), most of Phase 4's requirements are about changing how Claude behaves. The "tests" for behavior changes are manual audit runs. The automated tests above (AICR-01/02, RULE-01) only apply if we extract parsing logic into standalone scripts. If the parsing stays as natural-language instructions in SKILL.md, those tests become manual-only too.

## Open Questions

1. **Should AI Crawler Policy be a scored category or informational-only?**
   - What we know: Current 5 categories have weighted scoring. AI crawler policy is site-level, not per-page.
   - Recommendation: Keep it **informational with a letter grade** but NOT part of the weighted overall score. It's a strategic assessment, not an optimization metric. Adding it to the weighted score would change all existing scores.

2. **Should the bot list be maintained in SKILL.md or a separate reference file?**
   - What we know: Reference files are per-category audit rules. The bot list is a lookup table, not a set of checks.
   - Recommendation: Put the bot list and grading rubric in **SKILL.md** as part of the crawl phase instructions. It's an instruction, not a rule file.

3. **What does "update rules" mean for RULE-02?**
   - What we know: RULE-03 and RULE-04 (auto-research workflow) are v2 requirements, out of scope for Phase 4.
   - Recommendation: The staleness warning suggests "update rules" as a user action. For now, this means manually reviewing reference files. The warning text should say "reference files may be outdated -- consider reviewing them" rather than implying an automated update command exists.

## Sources

### Primary (HIGH confidence)
- [ai-robots-txt/ai.robots.txt](https://github.com/ai-robots-txt/ai.robots.txt/blob/main/robots.txt) - Comprehensive AI bot list maintained by community
- Project codebase: SKILL.md, report-template.md, references/*.md - Current implementation
- Existing audit reports - How robots.txt AI bots are currently reported

### Secondary (MEDIUM confidence)
- [Search Engine Journal - Anthropic's Claude Bots](https://www.searchenginejournal.com/anthropics-claude-bots-make-robots-txt-decisions-more-granular/568253/) - 3-bot framework details
- [robotstxt.com/ai](https://robotstxt.com/ai) - AI bot blocking guide
- [Momentic - AI Search Crawlers](https://momenticmarketing.com/blog/ai-search-crawlers-bots) - Bot list with descriptions
- [witscode - Robots.txt Strategy 2026](https://witscode.com/blogs/robots-txt-strategy-2026-managing-ai-crawlers/) - Training vs retrieval distinction

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new tools, all edits to existing files
- Architecture: HIGH - Three isolated features, no cross-dependencies
- AI bot list: MEDIUM - Bot landscape changes frequently, list is current as of March 2026
- Pitfalls: HIGH - Based on actual codebase analysis and existing audit reports

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (30 days - bot list may need updating after that)
