# Feature Landscape

**Domain:** Website audit tool (SEO/AEO/GEO)
**Researched:** 2026-03-05

## Table Stakes

Features the tool must have. Missing = audit results are unreliable or unusable.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Core Web Vitals scoring | 4 checks are permanently UNTESTABLE without it. Lighthouse CLI fixes this. | Low | Drop-in replacement for pagespeed.sh |
| Deterministic scoring | WARNING = half points must be explicit, not improvised | Low | Already documented in CONCERNS.md, just needs enforcement via code |
| Scoring regression tests | Reference file edits silently change scores. No way to catch drift. | Medium | Golden file approach with bash assert scripts |
| Modular SKILL.md | 304-line single file is fragile. One bad edit breaks everything. | Medium | Split into crawl, scoring, report modules |
| Report filename uniqueness | Same-day audits overwrite each other | Low | Already decided: use timestamp format |

## Differentiators

Features that make the tool significantly better but are not blocking.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| curl + Playwright hybrid crawl | 50-100x faster for static pages (0.1s vs 5-8s) | Medium | Needs detection logic: when does curl miss data that Playwright catches? |
| Page selection before crawling | User control over what gets audited | Low | Show discovered pages, ask which to crawl |
| Stale rule detection | Warn when reference files are 90+ days old | Low | Bash script checking Last reviewed dates |
| Guided rule research | Claude researches and proposes reference file updates | Medium | Needs source URLs in reference files for re-verification |
| Simplified compare mode | Score table only, drop full side-by-side reports | Low | Less output, same insight |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Fix mode | Reports are sufficient. Auto-fixing codebases is a different tool with different risks. | Prioritized fix list in report |
| Web dashboard | CLI-only tool. Web UI adds hosting, auth, deployment complexity for no audience. | Markdown reports in git |
| Custom MCP server | Adds a build/deploy step to what is currently zero-install. | Use Playwright MCP + system tools |
| Standalone CLI binary | Claude Code IS the interface. A standalone CLI duplicates the orchestration layer. | Keep as skill |
| Auto-apply rule updates | Reference file edits change scoring denominators silently. | Show diff, ask user to approve |
| Parallel Playwright crawling | Single browser instance causes stale DOM reads (confirmed in first audit run). | Sequential Playwright, parallel curl |
| Full Lighthouse HTML reports | Context-window waste. We only need scores and CWV metrics. | JSON output, extract only needed fields |

## Feature Dependencies

```
Lighthouse CLI script --> Scoring regression tests (need real CWV data in fixtures)
Modular SKILL.md --> Everything else (safer to edit modules than monolith)
curl extraction script --> Hybrid crawl strategy (need curl extraction working first)
Hybrid crawl --> Speed target (<1 minute)
Stale rule detection --> Guided rule research (detect first, then research)
Source URLs in reference files --> Guided rule research (Claude needs URLs to verify against)
```

## MVP Recommendation

Prioritize (in order):
1. **Lighthouse CLI script** -- Unblocks 4 UNTESTABLE checks. Highest impact, lowest effort.
2. **Modular SKILL.md** -- Makes everything else safer to build.
3. **Scoring regression tests** -- Catches silent breakage from any future change.
4. **Deterministic scoring** -- WARNING = half points, enforced.
5. **curl hybrid crawl** -- Speed improvement, independent of other features.

Defer:
- **Guided rule research** -- Reference files are 0 days old today. This becomes relevant in 90 days.
- **Simplified compare mode** -- Works fine as-is. Polish later.

---

*Feature research: 2026-03-05*
