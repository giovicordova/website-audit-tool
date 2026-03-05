# AEO — Answer Engine Optimization

## Source
Patterns observed from Perplexity AI, ChatGPT web search, Google AI Overviews. Princeton GEO paper (KDD 2024), BrightEdge analysis, SurferSEO citation report, TryProfound citation studies, SE Ranking AI stats.
Last reviewed: 2026-03-05

## Checks

### CRITICAL
- [ ] First paragraph directly answers the page's target question (check: does the first <p> or text block after H1 contain a direct answer statement?) — 44.2% of AI citations come from the first 30% of content
- [ ] "Answer Block" present — a clear, concise 40-60 word answer near the top of the page (ideal snippet length for AI citation)
- [ ] Key answers front-loaded in first 200 words (intro is 2x more important than conclusion for getting cited)
- [ ] Question-based heading patterns present on informational pages ("What is X", "How to X", "Why does X") — check H2/H3 tags (headers are extraction anchors for AI systems)
- [ ] Concise definitions appear before detailed explanations (check: is there a 1-2 sentence definition within the first 150 words?)
- [ ] FAQ section present with at least 3 Q&A pairs on informational/product pages — FAQ-heavy content with schema has 58% citation rate

### IMPORTANT
- [ ] Lists and tables used for comparison content (check: pages with comparative language have <ul>/<ol>/<table>) — listicles make up 32% of all AI citations; tables increase citation rates 2.5x vs prose
- [ ] Clear, unambiguous language — no filler phrases ("in order to", "it is important to note that") — AI prefers extractable, clear prose
- [ ] Each page targets one primary question (not trying to answer everything)
- [ ] Definitions use "X is..." or "X refers to..." patterns (easily extractable by AI)
- [ ] Sections are 100-150 words each (optimal citation length) — pages with 120-180 word sections earn 70% more citations by ChatGPT
- [ ] Statistics and specific numbers present in content — adding statistics boosts AI visibility up to 40% (Princeton GEO study)

### NICE TO HAVE
- [ ] Step-by-step numbered instructions for how-to content
- [ ] Summary/TL;DR section at top of long-form content
- [ ] Content structured so each section can stand alone as a citable passage
- [ ] Content depth: 2,000+ words for informational topics — articles over 2,900 words are 59% more likely to be cited by ChatGPT
  > **Exception:** Pages with `WebApplication` schema (app/tool landing pages) are intentionally minimal. For these pages, reduce the content-depth threshold to 200+ words and do not fail this check if the page serves a functional (non-informational) purpose.
- [ ] Balanced mix of facts and opinions (pure opinion or pure data alone perform worse than a blend)
