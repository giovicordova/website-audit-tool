# Architecture Patterns

**Domain:** Website audit tool (Claude Code skill)
**Researched:** 2026-03-05

## Recommended Architecture

### Current: Monolith SKILL.md (304 lines)
### Target: Modular skill with supporting scripts

```
SKILL.md                          # Orchestration only (~100 lines)
  |-- references/*.md             # Curated rules (existing, unchanged)
  |-- scripts/lighthouse.sh       # Lighthouse CLI wrapper (replaces pagespeed.sh)
  |-- scripts/curl-extract.sh     # Fast HTML extraction via curl + xmllint
  |-- scripts/check-staleness.sh  # Reference file freshness checker
  |-- tests/test-scoring.sh       # Scoring regression tests
  |-- tests/test-report.sh        # Report format validation
  |-- tests/fixtures/*.json       # Golden file test data
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| SKILL.md | Orchestration: parse request, dispatch phases, coordinate output | All other components (Claude reads and follows it) |
| scripts/lighthouse.sh | Run Lighthouse CLI, return structured JSON with scores + CWV | Called by Claude via bash, output parsed by Claude |
| scripts/curl-extract.sh | Fetch HTML with curl, extract metadata via xmllint, return JSON | Called by Claude via bash, output compared to Playwright data |
| scripts/check-staleness.sh | Check reference file dates, warn if stale | Called at audit start, output shown to user |
| references/*.md | Define checks, severities, and expected values for each category | Read by Claude during scoring phase |
| tests/*.sh | Validate scoring and report output against golden files | Run manually or via pre-commit hook |

### Data Flow

```
User request ("audit example.com")
  |
  v
SKILL.md Phase A: Parallel batch
  |-- curl: robots.txt, sitemap.xml, llms.txt, 404 test
  |-- scripts/lighthouse.sh: CWV + category scores
  |-- Playwright: homepage extraction (JS function)
  |-- Read: reference files
  |-- scripts/check-staleness.sh: freshness warning
  |
  v
SKILL.md Phase B: Discover pages
  |-- Combine sitemap + homepage links
  |-- Show user discovered pages, ask which to crawl
  |
  v
SKILL.md Phase C: Crawl pages (hybrid)
  |-- For each page: scripts/curl-extract.sh first
  |-- Compare curl output to Playwright output for accuracy
  |-- Fall back to Playwright for JS-heavy pages
  |
  v
SKILL.md Phase D: Score
  |-- Apply rules from references/*.md
  |-- Calculate per-category and weighted overall scores
  |
  v
SKILL.md Phase E: Report
  |-- Generate markdown report
  |-- Save to docs/w-audit/
```

## Patterns to Follow

### Pattern 1: Script Returns JSON to stdout
**What:** Every bash script outputs a single JSON object to stdout. Errors go to stderr.
**When:** Any data-producing script (lighthouse.sh, curl-extract.sh, check-staleness.sh).
**Why:** Claude can read JSON naturally. Structured output is unambiguous.

**Example:**
```bash
#!/bin/bash
# Success: JSON to stdout
echo '{"scores": {"performance": 95}, "error": null}'

# Failure: message to stderr, JSON error to stdout
echo "Lighthouse failed to start Chrome" >&2
echo '{"scores": null, "error": "Chrome launch failed"}'
exit 1
```

### Pattern 2: Golden File = Frozen Input + Expected Output
**What:** Test fixtures are pairs: input JSON (page data) and expected output JSON (scores).
**When:** Scoring validation.
**Why:** Detects silent regressions when reference files change check counts.

**Example:**
```
tests/fixtures/
  site-a-input.json         # Simulated extraction data
  site-a-expected.json      # Expected scores for that data
```

### Pattern 3: Skill Modules as Separate Markdown Files
**What:** Split SKILL.md sections into importable files that Claude reads when needed.
**When:** Any section that can operate independently (crawl strategy, scoring formula, report template).
**Why:** Smaller files = less risk per edit. Claude reads only what's needed per phase.

**Proposed split:**
```
SKILL.md              # Main entry: parse request, dispatch phases
skill/crawl.md        # Phase A-C: how to crawl, JS extraction function
skill/scoring.md      # Phase D: scoring formula, severity weights
skill/report.md       # Phase E: report template, compare mode
```

**How Claude reads modules:** SKILL.md instructs "Read `skill/crawl.md` for crawl instructions." Claude loads the file and follows its instructions. This is standard Claude Code skill behavior.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Putting Logic in Bash That Claude Should Decide
**What:** Writing complex conditional logic in bash scripts (e.g., "if score > 80, grade is B+").
**Why bad:** Claude already has the scoring formula in SKILL.md. Duplicating it in bash creates two sources of truth.
**Instead:** Scripts produce raw data. Claude applies the formula.

### Anti-Pattern 2: Caching Between Audit Runs
**What:** Saving previous audit results and trying to diff against them automatically.
**Why bad:** Audits should be independent. Cached state creates hard-to-debug inconsistencies.
**Instead:** Each audit runs fresh. Compare mode runs both sites in one session.

### Anti-Pattern 3: Passing Large HTML Through Script Arguments
**What:** `bash script.sh "$HUGE_HTML_STRING"`
**Why bad:** Bash argument limits (~2MB on macOS), escaping issues with quotes/special chars.
**Instead:** Scripts fetch their own HTML via curl. Pass URL, not content.

## Scalability Considerations

| Concern | Current (7 pages) | At 20 pages | At 50+ pages |
|---------|-------------------|-------------|-------------|
| Crawl time | ~60s (Playwright only) | ~3 min (Playwright only) | Not feasible |
| Crawl time with hybrid | ~15s (curl + selective Playwright) | ~45s | ~2 min |
| Context window | Comfortable | Tight with Playwright snapshots | Needs sampling strategy |
| Scoring time | Instant (Claude applies rules) | Same | Same |
| Report size | ~5KB | ~15KB | ~30KB |

**Scaling strategy:** For 20+ pages, sample by template type (one of each: homepage, about, blog post, product, contact) rather than crawling all linked pages.

## Sources

- Current codebase analysis (SKILL.md, scripts/pagespeed.sh)
- CONCERNS.md (documented fragility issues)
- Claude Code skill documentation (module pattern)

---

*Architecture research: 2026-03-05*
