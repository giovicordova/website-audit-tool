# SEO On-Page

## Source
Google Search Central, web.dev
Last reviewed: 2026-03-05

## Checks

### CRITICAL
- [ ] One H1 per page (check: exactly one <h1> tag exists)
- [ ] Title tag present and 50-60 characters (check: <title> tag length)
- [ ] Title tag unique across all audited pages (no duplicates)
- [ ] Meta description present and 150-160 characters
- [ ] Meta description unique across all audited pages

### IMPORTANT
- [ ] Heading hierarchy is correct (H1 > H2 > H3, no skipping levels — e.g., no H1 then H3)
- [ ] Images have descriptive alt text (check: all <img> tags have non-empty alt attributes)
- [ ] Internal links: every audited page is reachable from homepage within 3 clicks
- [ ] Clean URL structure (no query parameters for content pages, uses hyphens not underscores)
- [ ] H1 contains words related to the page's apparent topic

### NICE TO HAVE
- [ ] Alt text is descriptive, not just filename (e.g., not "IMG_1234" or "image1")
- [ ] No orphan pages (pages with zero internal links pointing to them)
- [ ] External links open in new tab (target="_blank" with rel="noopener")
- [ ] URL length under 75 characters

## Required Extraction Fields
- h1Count — "One H1 per page" check
- h1Text — "H1 contains topic words" check
- title — "Title tag present" check
- titleLength — "Title tag 50-60 characters" check
- metaDescription — "Meta description present" check
- metaDescriptionLength — "Meta description 150-160 characters" check
- headings — "Heading hierarchy correct" check
- images — "Images have descriptive alt text" check
- internalLinks — "Internal links within 3 clicks", "No orphan pages" checks
- externalLinks — "External links open in new tab" check
- url — "Clean URL structure", "URL length" checks

## Changelog

### 2026-03-05
- Initial version — sourced from Google Search Central, web.dev
