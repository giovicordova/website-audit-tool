---
phase: quick-2
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - modules/extraction.js
  - SKILL.md
  - references/aeo.md
  - references/geo.md
  - modules/report-template.md
autonomous: true
requirements: [QUICK-2-IMG, QUICK-2-CLAUDE-WEB, QUICK-2-STALENESS, QUICK-2-COMPARE, QUICK-2-WEBAPP]
must_haves:
  truths:
    - "Image extraction catches Next.js Image components, picture/source elements, and meaningful SVGs"
    - "Claude-Web legacy bot name is documented alongside Claude-User"
    - "Staleness check edge case and compare mode testing gap are noted for future test runs"
    - "AEO/GEO content-depth checks note that WebApplication-schema pages have adjusted expectations"
  artifacts:
    - path: "modules/extraction.js"
      provides: "Expanded image extraction covering img, picture>source, svg, next/image"
      contains: "picture"
    - path: "SKILL.md"
      provides: "Claude-Web legacy note and staleness test note"
      contains: "Claude-Web"
    - path: "references/aeo.md"
      provides: "WebApplication content-depth exception note"
      contains: "WebApplication"
    - path: "references/geo.md"
      provides: "WebApplication content-depth exception note"
      contains: "WebApplication"
  key_links: []
---

<objective>
Fix 5 actionable suggestions from the chapterpass.com audit log: expand image extraction selectors, document Claude-Web legacy bot name, add testing notes for staleness and compare mode, and add WebApplication content-depth exception to AEO/GEO references.

Purpose: Improve audit accuracy for modern frameworks and document known testing gaps.
Output: Updated extraction.js, SKILL.md, aeo.md, geo.md, report-template.md
</objective>

<execution_context>
@/Users/giovannicordova/.claude/get-shit-done/workflows/execute-plan.md
@/Users/giovannicordova/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@modules/extraction.js
@SKILL.md
@references/aeo.md
@references/geo.md
@modules/report-template.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Expand image extraction to cover Next.js, picture, and SVG elements</name>
  <files>modules/extraction.js</files>
  <action>
In modules/extraction.js, replace the current images extraction block (lines 27-32) with an expanded version that captures three additional image sources:

1. **picture > source elements**: Select `picture > source[srcset]` and map each to `{ src: source.srcset.split(',')[0].trim().split(' ')[0], alt: (source.closest('picture')?.querySelector('img')?.alt) || '', hasAlt: !!source.closest('picture')?.querySelector('img')?.hasAttribute('alt'), altIsDescriptive: ... (same regex test as current), type: 'picture-source' }`.

2. **Next.js Image components**: Select `img[data-nimg]` (Next.js adds this data attribute). These are already `img` tags so they'll be caught by the existing selector, but ALSO select `[style*="background-image"]` elements that Next.js sometimes uses for image placeholders. Map background-image elements to `{ src: extracted-url-from-style, alt: el.getAttribute('aria-label') || '', hasAlt: !!el.getAttribute('aria-label'), altIsDescriptive: ... , type: 'background-image' }`.

3. **Meaningful SVGs**: Select `svg[role="img"], svg[aria-label], svg:not([aria-hidden="true"]):not([role="presentation"])` but filter to only those with `getBoundingClientRect().width > 24` (skip tiny icons). Map to `{ src: 'inline-svg', alt: svg.getAttribute('aria-label') || svg.querySelector('title')?.textContent || '', hasAlt: !!(svg.getAttribute('aria-label') || svg.querySelector('title')), altIsDescriptive: ... , type: 'svg' }`.

Combine all four sources (existing img + picture source + background-image + svg) into the `images` array. Deduplicate by `src` (keep first occurrence). Update `imagesWithoutAlt` count to use the combined array.

Keep the existing `img` selector and its mapping exactly as-is for backward compatibility. The new sources are additive.
  </action>
  <verify>
    <automated>node -e "const fs = require('fs'); const code = fs.readFileSync('modules/extraction.js','utf8'); const checks = ['picture', 'data-nimg', 'background-image', 'svg[role', 'aria-label', 'getBoundingClientRect']; const missing = checks.filter(c => !code.includes(c)); if(missing.length) { console.error('Missing:', missing); process.exit(1); } console.log('All image selectors present');"</automated>
  </verify>
  <done>extraction.js captures img, picture source, background-image, and meaningful SVG elements with proper alt text detection for each type</done>
</task>

<task type="auto">
  <name>Task 2: Add Claude-Web legacy note, staleness test note, and compare mode test note</name>
  <files>SKILL.md, modules/report-template.md</files>
  <action>
Three documentation additions:

**A) SKILL.md -- Claude-Web legacy name (line ~44, in the AI Crawler Policy bot table)**

After the row `| Anthropic | Claude-User | Retrieval | Fetches pages during conversations |`, add a note line:
```
   > **Note:** Some sites use the legacy name "Claude-Web" for this bot. Treat "Claude-Web" as equivalent to "Claude-User" when classifying.
```

**B) SKILL.md -- Staleness check test note (near the staleness check section, around line 146-158)**

After the closing triple-backtick of the staleness warning example (after "Proceeding with audit..."), add:
```
> **Testing note:** The staleness warning path (>90 days) has not been exercised in production since reference files are regularly updated. Manually test by temporarily backdating a reference file's `Last reviewed` date.
```

**C) modules/report-template.md -- Compare mode test note**

At the end of the compare mode section (or at the end of the file if there's no distinct section), add:
```
<!-- Testing note: Compare mode template has not been exercised in a live audit yet. Run a compare audit (e.g., "compare site-a.com site-b.com") to verify formatting. -->
```
  </action>
  <verify>
    <automated>node -e "const fs = require('fs'); const skill = fs.readFileSync('SKILL.md','utf8'); const report = fs.readFileSync('modules/report-template.md','utf8'); let fail=false; if(!skill.includes('Claude-Web')){console.error('Missing Claude-Web note');fail=true;} if(!skill.includes('staleness warning path')){console.error('Missing staleness note');fail=true;} if(!report.includes('Compare mode')){console.error('Missing compare note');fail=true;} if(fail)process.exit(1); console.log('All notes present');"</automated>
  </verify>
  <done>Claude-Web legacy name documented in bot table, staleness test edge case noted, compare mode testing gap noted</done>
</task>

<task type="auto">
  <name>Task 3: Add WebApplication content-depth exception to AEO and GEO references</name>
  <files>references/aeo.md, references/geo.md</files>
  <action>
In both reference files, find the content-depth check line and add a note immediately after it:

**references/aeo.md** (the line reads: `Content depth: 2,000+ words for informational topics`):
Add on the next line:
```
  > **Exception:** Pages with `WebApplication` schema (app/tool landing pages) are intentionally minimal. For these pages, reduce the content-depth threshold to 200+ words and do not fail this check if the page serves a functional (non-informational) purpose.
```

**references/geo.md** (the line reads: `Content depth: pages are 800+ words for informational topics`):
Add on the next line:
```
  > **Exception:** Pages with `WebApplication` schema (app/tool landing pages) are intentionally minimal. For these pages, reduce the content-depth threshold to 200+ words and do not fail this check if the page serves a functional (non-informational) purpose.
```
  </action>
  <verify>
    <automated>node -e "const fs=require('fs'); let fail=false; ['references/aeo.md','references/geo.md'].forEach(f=>{const c=fs.readFileSync(f,'utf8'); if(!c.includes('WebApplication')){console.error(f+' missing WebApplication note');fail=true;}}); if(fail)process.exit(1); console.log('WebApplication exceptions present in both files');"</automated>
  </verify>
  <done>AEO and GEO reference files include WebApplication-schema exception for content-depth checks</done>
</task>

</tasks>

<verification>
All 5 suggestions addressed:
1. Image extraction gap -- expanded selectors in extraction.js
2. Claude-Web legacy name -- noted in SKILL.md bot table
3. Staleness check test path -- noted in SKILL.md
4. Compare mode untested -- noted in report-template.md
5. WebApplication content-depth -- exception added to aeo.md and geo.md
</verification>

<success_criteria>
- extraction.js selects img, picture>source, background-image, and meaningful SVG elements
- SKILL.md documents Claude-Web as legacy name for Claude-User
- SKILL.md notes staleness warning needs manual testing
- report-template.md notes compare mode needs a test run
- aeo.md and geo.md exempt WebApplication-schema pages from standard content-depth thresholds
</success_criteria>

<output>
After completion, create `.planning/quick/2-sort-out-chapterpass-com-audit-log-forma/2-SUMMARY.md`
</output>
