# GEO — Generative Engine Optimization

## Source
Google E-E-A-T guidelines, helpful content system documentation, GEO research papers (Princeton KDD 2024), Ahrefs brand visibility study (75K brands), SurferSEO AI citation report 2025, Search Engine Land GEO guides.
Last reviewed: 2026-03-05

## Checks

### CRITICAL
- [ ] Author name visible on content pages (check: byline, author bio, or author section present) — 96% of AI Overview citations come from sources with verified E-E-A-T signals
- [ ] Author credentials/expertise stated (check: bio mentions role, experience, or qualifications) — content from authors with established expertise is cited 340% more frequently
- [ ] Published date present on all content pages (check: <time> tag or visible date near title)
- [ ] Sources/references linked for factual claims (check: outbound links to authoritative sources exist) — adding citations improves AI visibility by 30-40%
- [ ] Structured data (JSON-LD) present on content pages — 82.5% of AI Overview citations come from pages with schema markup

### IMPORTANT
- [ ] Last-updated date present and distinct from published date (content freshness signal)
- [ ] Fact density: content contains specific, citable data — statistics, numbers, percentages, named examples (adding statistics boosts AI visibility up to 40%)
- [ ] Original data or unique perspective present (first-party data, case studies, original research — these are "citation magnets" for AI)
- [ ] Quotable passages — short (1-2 sentence), self-contained statements of fact that an AI could extract and cite verbatim (expert quotes boost visibility up to 40%)
- [ ] Organization/brand identity clear on every page (logo, consistent naming, about page linked)
- [ ] Entity density: pages reference 15+ recognized entities (names, places, organizations, concepts) — pages with 15+ entities show 4.8x higher AI citation probability
- [ ] Multimodal content: text + images + tables/charts on key pages — multimodal content yields 156% higher AI selection rates

### NICE TO HAVE
- [ ] Expert quotes with attribution
- [ ] Methodology or process described for any data/claims
- [ ] Content depth: pages are 800+ words for informational topics (not thin content)
  > **Exception:** Pages with `WebApplication` schema (app/tool landing pages) are intentionally minimal. For these pages, reduce the content-depth threshold to 200+ words and do not fail this check if the page serves a functional (non-informational) purpose.
- [ ] Content quality score above 8.5/10 — high-quality content is 4.2x more likely to appear in AI Overviews
- [ ] Answer-first content structure: lead with the direct answer, then expand

## Off-Site Recommendations (cannot be checked via crawl — included as advisory)
- **YouTube presence:** YouTube is the #1 correlated factor with AI visibility (r=0.737), overtaking Reddit in social citation share (39.2% vs 20.3%)
- **Reddit presence:** Reddit remains critical for sentiment signals; domains with millions of brand mentions on Reddit/Quora have ~4x higher citation likelihood
- **Review platform profiles:** Brands on Trustpilot, G2, Capterra have higher citation chance across AI platforms
- **Brand mentions:** Brand web mentions (r=0.664) and brand anchors (r=0.527) correlate more strongly with AI citation than traditional backlinks (r=0.218-0.312)
- **Wikipedia:** Accounts for 47.9% of ChatGPT's top-10 most-cited sources — having a Wikipedia presence matters
- **Multi-platform presence required:** Only 11% of domains get cited by both ChatGPT and Perplexity
- **New KPIs:** Share of AI Voice (SOV), Citation Frequency, and Brand Visibility Score are replacing traditional ranking metrics

## Required Extraction Fields
- headings — "Author name visible" (byline detection), heading structure checks
- timeTags — "Published date present" check
- publishedDate — "Published date present" check
- externalLinks — "Sources/references linked" check
- jsonLd — "Structured data present", "Entity density" checks
- bodyText — "Fact density", "Quotable passages", "Original data" checks
- bodyWordCount — "Content depth 800+ words" check
- images — "Multimodal content" check
- tableCount — "Multimodal content" (tables/charts) check

## Changelog

### 2026-03-05
- Initial version — sourced from Google E-E-A-T guidelines, helpful content system docs, Princeton GEO paper (KDD 2024), Ahrefs brand visibility study (75K brands), SurferSEO AI citation report 2025, Search Engine Land GEO guides
