# Requirements: Website Audit Tool v2

**Defined:** 2026-03-05
**Core Value:** Accurate, consistent scoring that produces the same results for the same site regardless of when or how many times the audit runs.

## v1 Requirements

### Performance Testing

- [ ] **PERF-01**: Lighthouse CLI replaces PageSpeed API for Core Web Vitals, performance, and accessibility checks
- [ ] **PERF-02**: Lighthouse script runs locally with no API key, no rate limits
- [ ] **PERF-03**: Lighthouse JSON output parsed into structured scoring data (LCP, INP, CLS, performance score, accessibility score)

### Scoring Accuracy

- [x] **SCOR-01**: Golden-file scoring tests detect regressions when reference files change
- [x] **SCOR-02**: Test fixtures use synthetic data (not real site snapshots) to avoid embedding current bugs as baselines
- [x] **SCOR-03**: Each reference file edit triggers a test that verifies score impact is intentional

### Modularization

- [ ] **MODU-01**: JS extraction function extracted to a separate file (extraction.js)
- [ ] **MODU-02**: Report template extracted to a separate file
- [ ] **MODU-03**: Scoring formula stays in main SKILL.md (per pitfalls research)
- [ ] **MODU-04**: SKILL.md reduced to orchestration-only (~150 lines)

### Crawl Speed

- [ ] **CRAW-01**: Full audit completes in under 1 minute (currently ~2-3 min)
- [ ] **CRAW-02**: Smart page selection: 3-4 pages by template diversity instead of 7 most-linked
- [ ] **CRAW-03**: Playwright optimizations: reuse browser context, minimize snapshot processing
- [ ] **CRAW-04**: Always show discovered pages and let user choose which to audit before crawling

### AI Crawler Policy

- [ ] **AICR-01**: Grade robots.txt AI bot strategy (distinguish training bots vs retrieval bots)
- [ ] **AICR-02**: Report which AI bots are allowed, blocked, or unaddressed
- [ ] **AICR-03**: Provide actionable recommendation for AI crawler policy

### Rule Maintenance

- [ ] **RULE-01**: Detect stale reference files (>90 days since last review)
- [ ] **RULE-02**: Warn user at audit start when rules are stale, suggest running update

### Compare Mode

- [ ] **COMP-01**: Simplified compare mode outputs score-comparison table only
- [ ] **COMP-02**: Drop full side-by-side category reports from compare output

## v2 Requirements

### Rule Auto-Update

- **RULE-03**: Auto-research workflow where Claude checks rules against official sources
- **RULE-04**: User approval required before applying any rule changes

### Advanced Crawl

- **CRAW-05**: curl + xmllint hybrid for static HTML pages (0.06s vs 5-8s per page)
- **CRAW-06**: Auto-detect JS-rendered vs static pages to choose crawl method

### Content Depth

- **CONT-01**: Entity density scoring using structural signals (not AI interpretation)
- **CONT-02**: Answer block detection (40-60 word direct answer in first 200 words)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Fix mode (auto-edit codebases) | Reports are sufficient, user fixes manually |
| Web dashboard | CLI-only via Claude Code |
| HTML report export | Markdown is sufficient, git-tracked |
| Content quality scoring via AI | Breaks deterministic scoring (core value) |
| Custom MCP servers | Playwright + curl + Lighthouse CLI covers everything |
| Standalone CLI tool | Claude Code is the interface |
| Agent SDK application | Claude Code IS the agent |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PERF-01 | Phase 1 | Pending |
| PERF-02 | Phase 1 | Pending |
| PERF-03 | Phase 1 | Pending |
| SCOR-01 | Phase 1 | Complete |
| SCOR-02 | Phase 1 | Complete |
| SCOR-03 | Phase 1 | Complete |
| MODU-01 | Phase 2 | Pending |
| MODU-02 | Phase 2 | Pending |
| MODU-03 | Phase 2 | Pending |
| MODU-04 | Phase 2 | Pending |
| CRAW-01 | Phase 3 | Pending |
| CRAW-02 | Phase 3 | Pending |
| CRAW-03 | Phase 3 | Pending |
| CRAW-04 | Phase 3 | Pending |
| AICR-01 | Phase 4 | Pending |
| AICR-02 | Phase 4 | Pending |
| AICR-03 | Phase 4 | Pending |
| RULE-01 | Phase 4 | Pending |
| RULE-02 | Phase 4 | Pending |
| COMP-01 | Phase 4 | Pending |
| COMP-02 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0

---
*Requirements defined: 2026-03-05*
*Last updated: 2026-03-05 after roadmap creation*
