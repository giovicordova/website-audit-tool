# Project Research Summary

**Project:** Website Audit Tool v2
**Domain:** Website audit (SEO/AEO/GEO) -- Claude Code skill
**Researched:** 2026-03-05
**Confidence:** HIGH

## Executive Summary

This is a Claude Code skill that audits websites across SEO, AEO (Answer Engine Optimization), GEO (Generative Engine Optimization), and structured data categories. The existing v1 is a 304-line monolith SKILL.md with a broken performance testing pipeline (PageSpeed API dependency removed, 4 checks permanently UNTESTABLE). The tool works but has fragility issues: non-deterministic scoring, no regression tests, and a single-file architecture where one bad edit breaks everything. All required tooling (Lighthouse CLI, curl, xmllint, jq) is already installed on this machine -- zero new dependencies needed.

The recommended approach is a modular rewrite: replace pagespeed.sh with a Lighthouse CLI wrapper, split SKILL.md into 3-4 focused modules, add golden-file scoring tests, and introduce a curl+xmllint hybrid crawl for speed. The existing Playwright MCP stays as a fallback for JS-rendered sites. This is not a greenfield build -- it is a targeted restructuring of a working tool to fix known gaps and reduce fragility.

The key risks are: Lighthouse score variance between runs (5-10 point swings on real sites), curl silently missing JS-rendered content (producing false FAILs), and reference file edits silently changing all historical scores. Each has a concrete mitigation: document margin of error, compare curl vs Playwright on the homepage before committing to curl-only, and run golden-file tests after any reference file change.

## Key Findings

### Recommended Stack

Zero-install stack. Every tool is already on this machine and verified working.

**Core technologies:**
- **Lighthouse CLI (12.5.1):** Performance/accessibility/SEO/best-practices scores + Core Web Vitals -- replaces broken pagespeed.sh entirely
- **curl + xmllint:** Fast HTML extraction (0.1s/page vs 5-8s with Playwright) -- system-installed, XPath-based metadata parsing
- **Playwright MCP:** JS-rendered page extraction -- existing, kept as fallback for SPAs and dynamic content
- **jq:** JSON extraction from Lighthouse output -- compact 200-byte results from 500KB+ raw reports
- **Bash assert scripts:** Scoring regression tests via golden file diffing -- no framework dependency needed for <20 tests

**Version constraint:** Lighthouse 13.x requires Node 22.19+, this system has 22.16.0. Stay on 12.x. Scoring is identical between versions.

### Expected Features

**Must have (table stakes):**
- Core Web Vitals scoring -- 4 checks are UNTESTABLE without it
- Deterministic scoring -- WARNING = half points, enforced in code not improvised
- Scoring regression tests -- catch silent drift from reference file edits
- Modular SKILL.md -- split monolith into 3-4 files to reduce edit risk
- Unique report filenames -- timestamp format, prevent same-day overwrites

**Should have (differentiators):**
- curl + Playwright hybrid crawl -- 50-100x faster for static sites
- Page selection before crawling -- user picks which discovered pages to audit
- Stale rule detection -- warn when reference files are 90+ days old

**Defer (v2+):**
- Guided rule research -- reference files are 0 days old, relevant in 90 days
- Simplified compare mode -- works fine today, polish later
- Fix mode, web dashboard, custom MCP server -- explicitly anti-features

### Architecture Approach

Modular skill with supporting bash scripts. SKILL.md becomes a ~100-line orchestrator that dispatches to focused modules (crawl, scoring, report) and calls bash scripts for data production. Scripts output JSON to stdout, errors to stderr. Claude applies scoring formulas -- scripts never contain scoring logic (single source of truth). Maximum 3-4 module files to avoid wasting tool calls on excessive splitting.

**Major components:**
1. **SKILL.md** -- orchestration: parse request, dispatch phases, coordinate output
2. **skill/crawl.md** -- crawl strategy: curl extraction, Playwright fallback, hybrid detection
3. **skill/scoring.md** -- scoring formula: severity weights, WARNING half-points, per-category calculation
4. **skill/report.md** -- report template: section structure, compare mode, output formatting
5. **scripts/*.sh** -- data producers: lighthouse.sh, curl-extract.sh, check-staleness.sh (all return JSON)
6. **tests/*.sh** -- validation: scoring regression tests, report format checks, golden file fixtures

### Critical Pitfalls

1. **Lighthouse score variance (5-10 points between runs)** -- Document margin of error in reports. Do not cache or average multiple runs.
2. **curl misses JS-rendered content silently** -- Compare curl vs Playwright on the homepage once per audit. If curl misses critical fields, flag site as JS-rendered and use Playwright for all pages.
3. **Reference file edits change all scores silently** -- Golden file tests catch this. Run test-scoring.sh after any reference file change. Update fixtures deliberately.
4. **Over-splitting SKILL.md wastes context** -- Cap at 3-4 module files. Each file read is a tool call.
5. **Lighthouse JSON is 500KB-1MB** -- Extract only scores and CWV via jq before passing to Claude. Never pass raw Lighthouse output.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Lighthouse CLI Integration
**Rationale:** Highest impact, lowest effort. Unblocks 4 UNTESTABLE checks. No dependency on other work.
**Delivers:** Working lighthouse.sh script that returns compact JSON with category scores and Core Web Vitals.
**Addresses:** Core Web Vitals scoring (table stakes), replaces broken pagespeed.sh
**Avoids:** Score variance pitfall (documents margin of error), large JSON pitfall (jq extraction)

### Phase 2: SKILL.md Modularization
**Rationale:** Makes everything else safer to build. Editing a 304-line monolith is the highest-risk activity. Must happen before adding new features.
**Delivers:** SKILL.md (~100 lines) + skill/crawl.md + skill/scoring.md + skill/report.md
**Addresses:** Modular SKILL.md (table stakes), deterministic scoring enforcement
**Avoids:** Over-splitting pitfall (3-4 files max)

### Phase 3: Scoring Tests and Determinism
**Rationale:** Depends on Phase 2 (scoring formula must be in its own module before testing it). Creates the safety net for all future changes.
**Delivers:** tests/test-scoring.sh, tests/test-report.sh, tests/fixtures/*.json, enforced WARNING = half points
**Addresses:** Scoring regression tests (table stakes), deterministic scoring (table stakes)
**Avoids:** Reference file edit pitfall (golden files detect score drift)

### Phase 4: Hybrid Crawl
**Rationale:** Independent of scoring work but depends on modular SKILL.md (crawl logic lives in skill/crawl.md). Biggest speed improvement.
**Delivers:** scripts/curl-extract.sh, homepage curl-vs-Playwright comparison, automatic fallback logic
**Addresses:** curl hybrid crawl (differentiator), unique report filenames (table stakes)
**Avoids:** Silent JS-content miss pitfall (homepage comparison gate)

### Phase 5: Reference File Maintenance
**Rationale:** Low urgency (files are 0 days old). Builds on stable foundation from phases 1-4.
**Delivers:** scripts/check-staleness.sh, source URLs added to reference files, research prompt in SKILL.md
**Addresses:** Stale rule detection (differentiator), groundwork for guided rule research (deferred)
**Avoids:** Auto-apply pitfall (always show diff, require user approval)

### Phase Ordering Rationale

- Phases 1-3 follow a strict dependency chain: Lighthouse data feeds scoring, modular structure enables safe scoring changes, tests lock down scoring behavior
- Phase 4 (hybrid crawl) is architecturally independent but benefits from modular SKILL.md being in place
- Phase 5 is pure future-proofing with no current urgency
- Each phase delivers a working improvement -- no phase depends on a later phase to be useful

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Modularization):** How Claude Code handles multi-file skill reading needs validation. The module pattern is documented but not battle-tested in this project.
- **Phase 4 (Hybrid Crawl):** The curl-vs-Playwright comparison heuristic needs real-world testing. Which fields reliably indicate JS-rendering? Research needed.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Lighthouse):** Fully verified. Command, JSON paths, and extraction script are tested on this machine.
- **Phase 3 (Scoring Tests):** Standard golden-file testing. Bash assert pattern is simple and documented.
- **Phase 5 (Staleness):** Straightforward date comparison. Script already written in STACK.md research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All tools verified locally. Lighthouse JSON paths confirmed against real output. |
| Features | HIGH | Clear table stakes vs differentiators. Feature dependencies mapped. Anti-features explicitly scoped out. |
| Architecture | MEDIUM | Module pattern is sound but untested in this project. 3-4 file split is a judgment call. |
| Pitfalls | HIGH | Top pitfalls observed in actual testing (Lighthouse variance, curl gaps, xmllint warnings). |

**Overall confidence:** HIGH

### Gaps to Address

- **SKILL.md module loading pattern:** Need to validate that Claude reliably reads referenced module files during skill execution. Test with a simple 2-file split before committing to the full 4-file structure.
- **curl-vs-Playwright detection threshold:** Research identified the need to compare curl and Playwright output, but did not define which specific missing fields trigger the "JS-rendered" flag. Define during Phase 4 planning.
- **Scoring formula codification:** The current scoring formula has ambiguity around WARNING = half points. Phase 3 must nail down the exact formula before writing tests.
- **Fixture generation strategy:** How to create representative test data without running real audits. Needs attention during Phase 3 planning.
- **Source URLs in reference files:** Currently reference files do not cite their sources, making research verification harder. Address in Phase 5.

## Sources

### Primary (HIGH confidence)
- Lighthouse CLI: verified locally via `npx lighthouse` on example.com. JSON paths confirmed.
- curl + xmllint: verified locally on example.com and web.dev. Extraction timing measured.
- [Lighthouse GitHub docs](https://github.com/GoogleChrome/lighthouse/blob/main/readme.md) -- CLI flags, output format
- [Lighthouse understanding-results.md](https://github.com/GoogleChrome/lighthouse/blob/main/docs/understanding-results.md) -- JSON output structure
- Current codebase: SKILL.md (304 lines), CONCERNS.md (documented issues), pagespeed.sh (broken)

### Secondary (MEDIUM confidence)
- [What's new in Lighthouse 13](https://developer.chrome.com/blog/lighthouse-13-0) -- version 13 changes, Node requirement
- Claude Code skill module pattern: documented but not tested in multi-file configuration for this project
- Bash testing approach: based on Claude Code best practices docs

### Tertiary (LOW confidence)
- Auto-research workflow: novel pattern, no established precedent for "Claude updates its own reference files"
- Hybrid crawl heuristics: curl-vs-Playwright comparison logic needs real-world validation beyond two test sites

---
*Research completed: 2026-03-05*
*Ready for roadmap: yes*
