# Phase 3: Fast Crawl - Research

**Researched:** 2026-03-05
**Domain:** Crawl speed optimization, smart page selection, Playwright/chrome-devtools-mcp session reuse
**Confidence:** HIGH

## Summary

Phase 3 targets four improvements to the crawl phase: (1) total audit time under 1 minute, (2) smart page selection by template diversity instead of most-linked, (3) browser context reuse across pages, and (4) showing discovered pages to the user for selection before crawling.

The current crawl flow takes ~2-3 minutes for a 7-page audit. The biggest time sinks are: Lighthouse CLI (~15-20s), sequential Playwright page crawls (~5-8s per page x 7 = 35-56s), and Claude processing time between pages. The project uses `chrome-devtools-mcp` (not Playwright MCP as some docs state) which already maintains a persistent browser session -- meaning `navigate_page` reuses the same browser instance. The key optimization is reducing the number of pages crawled (from 7 to 3-4 via template diversity) and ensuring we never spin up new browser contexts.

The user-choice requirement (CRAW-04) means the crawl flow becomes interactive: discover pages, present them grouped by template type, let the user pick, then crawl only those. This naturally reduces crawl time because users typically pick 3-4 representative pages.

**Primary recommendation:** Reduce pages from 7 to 3-4 via template diversity scoring, add an interactive page selection step before crawling, and update SKILL.md crawl instructions to reuse the existing browser session via `navigate_page` (never `new_page`).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CRAW-01 | Full audit completes in under 1 minute (currently ~2-3 min) | Reducing pages from 7 to 3-4 saves 15-24s. Template diversity selection means fewer pages with the same coverage. Lighthouse (~15-20s) is the fixed cost floor -- everything else must fit in ~40s. |
| CRAW-02 | Smart page selection: 3-4 pages by template diversity instead of 7 most-linked | Group discovered URLs by template type (homepage, blog listing, blog post, product, about, FAQ, contact). Pick one representative from each type. Prioritize types with unique schema/content patterns. |
| CRAW-03 | Playwright optimizations: reuse browser context, minimize snapshot processing | The project uses `chrome-devtools-mcp` which already maintains a persistent browser session. Use `navigate_page` for each URL (reuses existing tab). Never use `new_page`. Disable snapshots by not calling `take_snapshot`. |
| CRAW-04 | Always show discovered pages and let user choose which to audit before crawling | After Phase A+B (homepage crawl + page discovery), present grouped URLs to user. Wait for selection. Then crawl only selected pages in Phase C. |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| chrome-devtools-mcp | latest (via npx) | Browser navigation + JS evaluation | Already configured as project's MCP server. Persistent session across navigations. |
| curl | system | robots.txt, sitemap.xml, llms.txt, 404 test | Already used in Phase A. Fast, no browser needed. |
| Lighthouse CLI (npx) | 12.5.1 | Performance/accessibility/SEO scores + CWV | Already integrated in scripts/lighthouse.sh. Fixed ~15-20s cost. |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| jq | system | Parse sitemap XML, Lighthouse JSON | Already in use for Lighthouse output extraction |
| python3 | system | Scoring calculations | Already in scripts/score.py |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reducing page count | Parallel crawling | chrome-devtools-mcp shares a single browser instance. Concurrent navigations cause stale DOM reads (confirmed in first audit). Sequential with fewer pages is the right approach. |
| chrome-devtools-mcp | curl+xmllint hybrid | Deferred to v2 (CRAW-05/06). Risk of missing JS-rendered content. Playwright-first is safer. |

## Architecture Patterns

### Current Crawl Flow (SKILL.md)
```
Phase A: parallel — curl x4 + Playwright homepage + read refs + Lighthouse    (~20s)
Phase B: discover pages from sitemap + homepage links                         (~1s)
Phase C: crawl 5 internal pages sequentially via Playwright                   (~30-40s)
Phase D: crawl 1 blog post via Playwright                                     (~6-8s)
                                                                    TOTAL:    ~57-69s
```

### Optimized Crawl Flow
```
Phase A: parallel — curl x4 + navigate_page homepage + read refs + Lighthouse  (~20s)
Phase B: discover pages, classify by template type                             (~1s)
Phase B2: PRESENT pages to user, WAIT for selection (3-4 pages)                (user time)
Phase C: crawl selected pages via navigate_page (reuse same tab)               (~15-24s)
                                                                     TOTAL:    ~36-45s
```

### Key Changes
1. **Phase B gains a classification step** -- group URLs by template type before presenting
2. **Phase B2 is NEW** -- interactive user selection replaces auto-picking
3. **Phase C shrinks** -- 3-4 pages instead of 5-7
4. **Phase D is absorbed into Phase C** -- if user selects a blog post, it's just another page in the list

### Pattern 1: Template Type Classification
**What:** Classify discovered URLs by likely page template using URL patterns and sitemap structure.
**When to use:** Phase B, after collecting URLs from sitemap + homepage links.

URL pattern heuristics:
```
/                     → homepage
/blog, /news, /posts  → blog-listing
/blog/*, /posts/*     → blog-post
/about, /team         → about
/faq, /help           → faq
/pricing, /plans      → pricing
/contact              → contact
/products/*, /shop/*  → product
/docs/*, /help/*      → documentation
/case-studies/*       → case-study
/[slug]               → landing-page (catch-all for top-level pages)
```

Presentation to user:
```
Found 12 pages. Grouped by template type:

Homepage (1):     /
Blog listing (1): /blog
Blog posts (4):   /blog/post-1, /blog/post-2, /blog/post-3, /blog/post-4
About (1):        /about
FAQ (1):          /faq
Landing (2):      /pricing, /for/acx
Glossary (1):     /glossary
Contact (1):      /contact

Recommended (4): /, /blog/post-1, /faq, /for/acx
(1 per unique template type, prioritizing pages with distinct content patterns)

Which pages should I audit? [pick from above or say "recommended"]
```

### Pattern 2: Browser Session Reuse
**What:** Use `navigate_page` to move the existing browser tab to each URL instead of opening new tabs.
**When to use:** Every page crawl in Phase C.

Flow per page:
1. `navigate_page` to URL (reuses existing tab, ~2-3s for navigation)
2. `evaluate_script` with extraction.js (~1-2s for JS execution)
3. Move to next page (no cleanup needed)

Never use `new_page` -- it creates additional tabs that consume memory and aren't needed for sequential crawling.

### Pattern 3: Snapshot Avoidance
**What:** Never call `take_snapshot` during crawl phase.
**When to use:** Always during audits.

The SKILL.md currently says nothing about snapshots, but Claude sometimes takes snapshots by default after navigation. The SKILL.md should explicitly say: "Do NOT take snapshots or screenshots during crawl -- the JS extraction function captures all needed data."

### Anti-Patterns to Avoid
- **Opening new tabs per page:** `new_page` creates tabs that persist and consume memory. Use `navigate_page` on the existing tab.
- **Taking snapshots:** Snapshots consume context window tokens (~10-20K per page) without providing audit value. The JS extraction function captures everything needed.
- **Crawling duplicate template types:** Auditing 3 blog posts when 1 is sufficient. Template diversity means pick ONE from each type.
- **Auto-selecting pages without user input:** CRAW-04 requires user choice. The "recommended" shortcut is fine but the user must see the list.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL template classification | ML classifier or NLP | Simple URL pattern matching (regex on path segments) | URL structure is predictable. /blog/* is always blog. No need for ML. |
| Page deduplication | Content similarity hashing | URL pattern grouping | Same template type = same content structure. We only need 1 per type. |
| Browser session management | Custom Chrome launcher | chrome-devtools-mcp's built-in session persistence | MCP server handles Chrome lifecycle. navigate_page reuses the session. |
| Interactive page selection | Custom CLI prompts | Claude's conversational interface | Claude naturally presents choices and waits for user response. This is just a list + question in the chat. |

**Key insight:** The speed improvement comes from doing LESS (fewer pages, no snapshots), not from doing things faster. The chrome-devtools-mcp already handles session reuse. The main work is changing SKILL.md instructions.

## Common Pitfalls

### Pitfall 1: Lighthouse Is the Time Floor
**What goes wrong:** Optimizing everything else but Lighthouse still takes 15-20s, making sub-30s impossible.
**Why it happens:** Lighthouse spins up its own Chrome instance, loads the page with throttling, runs all audits.
**How to avoid:** Accept Lighthouse as a fixed ~15-20s cost. The 1-minute budget gives ~40s for everything else. Don't try to speed up Lighthouse -- it's already running with `--quiet` and targeted categories.
**Warning signs:** Trying to run Lighthouse in parallel with page crawls (risks port conflicts with Chrome instances).

### Pitfall 2: Claude Takes Snapshots Automatically
**What goes wrong:** After `navigate_page`, Claude calls `take_snapshot` to "see" the page, consuming 5-10s and context tokens.
**Why it happens:** Some Claude Code patterns encourage visual verification after navigation.
**How to avoid:** Add explicit instruction in SKILL.md: "Do NOT take snapshots or screenshots during crawl. The JS extraction function captures all needed data."
**Warning signs:** Audit logs showing snapshot calls between navigations.

### Pitfall 3: Template Classification Misses JS-Rendered Routes
**What goes wrong:** A URL like `/app/dashboard` looks like a landing page but is actually a dynamic app page.
**Why it happens:** URL patterns can't distinguish static from dynamic content without loading the page.
**How to avoid:** Don't worry about it. The user sees the page list and can deselect anything irrelevant. The interactive step (CRAW-04) is the safety net.
**Warning signs:** None -- user selection handles this.

### Pitfall 4: User Selection Adds Delay
**What goes wrong:** The "interactive selection" step blocks the audit while waiting for user input, making total wall-clock time longer.
**Why it happens:** We stop and wait for the user to pick pages.
**How to avoid:** Run Lighthouse in parallel with the user's decision. While the user reads the page list and picks, Lighthouse is already running in the background (it only needs the homepage URL, which we have from Phase A).
**Warning signs:** Lighthouse not starting until after user selection.

### Pitfall 5: evaluate_script vs browser_evaluate Naming
**What goes wrong:** SKILL.md says `browser_evaluate` but chrome-devtools-mcp uses `evaluate_script`.
**Why it happens:** The project docs reference "Playwright MCP" tool names but the actual MCP is chrome-devtools-mcp with different tool names.
**How to avoid:** Update SKILL.md to use `evaluate_script` (the actual chrome-devtools-mcp tool name). Or keep using `browser_evaluate` if Claude already maps it correctly -- verify with a test crawl.
**Warning signs:** "Tool not found" errors during crawl.

## Code Examples

### Template Type Classification (for SKILL.md instructions)
```
Classify each discovered URL by its path pattern:

- /                           → "homepage"
- /blog, /news, /posts        → "blog-listing"
- /blog/*, /news/*, /posts/*   → "blog-post"
- /about, /team, /company     → "about"
- /faq, /help, /support       → "faq"
- /pricing, /plans            → "pricing"
- /contact, /get-in-touch     → "contact"
- /products/*, /shop/*        → "product"
- /docs/*, /documentation/*   → "docs"
- /case-study/*, /customers/* → "case-study"
- /[single-segment]           → "landing-page"

If a URL doesn't match any pattern, classify as "other".
Group URLs by type. Pick 1 representative from each type (prefer shorter URLs).
```

### Updated SKILL.md Phase B/C Flow
```markdown
#### Phase B: Discover and classify pages

Combine sitemap URLs + homepage internal links. Remove duplicates.
Classify each URL by template type (homepage, blog-listing, blog-post,
about, faq, pricing, contact, product, docs, landing-page, other).

Present the grouped list to the user:

"Found {N} pages across {M} template types:
{type} ({count}): {url1}, {url2}, ...
...
Recommended ({3-4}): {one per unique type, prioritizing types with
distinct content patterns like FAQ, blog-post, landing-page}

Which pages should I audit? Pick from above or say 'recommended'."

Wait for the user's selection before proceeding.

#### Phase C: Crawl selected pages (sequential, reuse browser session)

For each selected page:
1. navigate_page to URL (reuses existing browser tab)
2. evaluate_script with the JS extraction function (see Section 1.1)
3. Do NOT take snapshots or screenshots -- the extraction function captures all needed data

Continue to the next page immediately after extraction completes.
```

### Timing Budget
```
Target: < 60 seconds total

Phase A (parallel):
  - curl x4:                 ~1s (parallel)
  - navigate_page homepage:  ~3-5s
  - evaluate_script homepage: ~1-2s
  - Read reference files:     ~1s
  - Lighthouse:               ~15-20s (dominates)
  Phase A total:              ~15-20s (limited by Lighthouse)

Phase B + B2:
  - URL classification:       ~1s (Claude processing)
  - User selection:           (not counted -- user time)
  Phase B total:              ~1s + user time

Phase C (3-4 pages):
  - navigate_page + evaluate_script per page: ~4-6s
  - 3-4 pages:               ~12-24s
  Phase C total:              ~12-24s

Scoring + Report:
  - Claude processing:        ~10-15s

TOTAL (excluding user time): ~38-60s
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 7 most-linked pages | 3-4 by template diversity | This phase | Same coverage, fewer pages, faster |
| Auto-select pages | User selects from grouped list | This phase | User control, avoids irrelevant pages |
| Phase D (separate blog step) | Blog post included in Phase C selection | This phase | Simpler flow, one crawl loop |
| Implicit browser session | Explicit navigate_page reuse | This phase | Clear instructions prevent new tab creation |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash test scripts (same as Phase 1/2) |
| Config file | None |
| Quick run command | `bash tests/test-scoring.sh` |
| Full suite command | `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CRAW-01 | Audit completes in under 1 minute | manual-only | Time a real audit run. No synthetic test possible -- depends on network + Lighthouse + chrome-devtools-mcp. | N/A |
| CRAW-02 | Template diversity selection in SKILL.md | inspection | `grep -q "template type" SKILL.md && echo PASS` | SKILL.md exists |
| CRAW-03 | Browser reuse instructions in SKILL.md | inspection | `grep -q "navigate_page" SKILL.md && echo PASS` | SKILL.md exists |
| CRAW-04 | User page selection in SKILL.md | inspection | `grep -q "Which pages should I audit" SKILL.md && echo PASS` | SKILL.md exists |
| REGRESSION | Scoring tests still pass | unit | `bash tests/test-scoring.sh` | Yes |
| REGRESSION | Lighthouse tests still pass | unit | `bash tests/test-lighthouse-output.sh` | Yes |

### Sampling Rate
- **Per task commit:** `bash tests/test-scoring.sh`
- **Per wave merge:** `bash tests/test-scoring.sh && bash tests/test-lighthouse-output.sh`
- **Phase gate:** Full suite green + manual audit timing < 60s

### Wave 0 Gaps
None -- this phase modifies SKILL.md instructions only. No new scripts or test infrastructure needed. Existing regression tests cover scoring/lighthouse. Speed and correctness validated by running a real audit.

## Open Questions

1. **chrome-devtools-mcp tool names vs SKILL.md terminology**
   - What we know: SKILL.md says "Playwright" and "browser_evaluate". The actual MCP is chrome-devtools-mcp with tools like `navigate_page` and `evaluate_script`.
   - What's unclear: Does Claude already map "browser_evaluate" to `evaluate_script` automatically, or will it fail?
   - Recommendation: Update SKILL.md to use the correct tool names (`navigate_page`, `evaluate_script`). Test with one crawl to verify.

2. **Lighthouse parallel with user selection**
   - What we know: Lighthouse only needs the homepage URL. User selection happens after page discovery.
   - What's unclear: Can Lighthouse run in the background while Claude presents the page list to the user?
   - Recommendation: Yes -- SKILL.md should instruct to fire Lighthouse in Phase A (parallel batch) alongside the homepage crawl. It finishes during or after user selection.

3. **Default page count when user says "recommended"**
   - What we know: CRAW-02 says 3-4 pages by template diversity.
   - What's unclear: Should "recommended" always pick exactly 4, or vary by site?
   - Recommendation: Pick 1 per unique template type, cap at 4. A site with 6 template types gets 4 (most diverse); a site with 2 types gets 2. The homepage always counts as one.

## Sources

### Primary (HIGH confidence)
- SKILL.md (current crawl flow, lines 25-65) -- direct analysis
- chrome-devtools-mcp GitHub README -- tool names and session behavior verified
- PROJECT.md (constraints: under 1 minute, no custom MCP servers)
- REQUIREMENTS.md (CRAW-01 through CRAW-04 definitions)
- STATE.md (decision: curl hybrid deferred to v2)
- Existing audit report (chapterpass.com) -- 7 pages crawled, template types observed

### Secondary (MEDIUM confidence)
- chrome-devtools-mcp npm page -- tool list and capabilities
- Phase 1 + Phase 2 research docs -- patterns and constraints carried forward

### Tertiary (LOW confidence)
- None. All findings verified against project files or official documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new tools, only SKILL.md instruction changes
- Architecture: HIGH - based on direct analysis of current flow and chrome-devtools-mcp capabilities
- Pitfalls: HIGH - based on confirmed issues from prior audit runs (stale DOM from concurrent navigation, snapshot context waste)
- Timing estimates: MEDIUM - based on observed audit times (~2-3 min for 7 pages) but individual step timing is estimated

**Research date:** 2026-03-05
**Valid until:** 2026-04-05 (stable domain, no version-dependent changes)
