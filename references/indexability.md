# Indexability

## Source
Google Search Central — "Why pages aren't indexed" (URL Inspection / Index Coverage report)
Last reviewed: 2026-03-09

## Scope
These checks detect 4 of the 16 GSC "not indexed" reasons that are observable from a crawl alone:
noindex directives, soft 404s, canonical mismatches, and excessive redirects.
Scored under **SEO Technical** (not a separate category).

## Data Sources
- `robotsMeta` / `googlebotMeta` — from extraction.js (meta tag content)
- `xRobotsTag` — from Playwright response headers
- `httpStatus` — from Playwright response status
- `finalUrl` — from Playwright page URL after navigation
- `redirectCount` — from Playwright redirect chain
- `bodyWordCount` — from extraction.js
- `canonical` — from extraction.js
- Sitemap URL spot-check — from Phase A curl probes

## Checks

### CRITICAL
- [ ] No `<meta name="robots" content="noindex">` on content pages (check `robotsMeta` and `googlebotMeta` fields for "noindex" directive)
- [ ] No `X-Robots-Tag: noindex` header (check `xRobotsTag` field for "noindex" directive)
- [ ] No soft 404s: pages returning HTTP 200 with `bodyWordCount` < 50 are likely soft 404s (flag for review)

### IMPORTANT
- [ ] Canonical is self-referencing or points to a valid URL within the same domain
- [ ] Canonical target URL returns HTTP 200 (cross-reference against crawled page data where available)
- [ ] All sitemap URLs return HTTP 200 (checked via Phase A spot-check of up to 20 sitemap URLs)
- [ ] No excessive redirect chains (`redirectCount` >= 3 indicates a chain that should be shortened)

### NICE TO HAVE
- [ ] Sitemap URLs do not redirect (`finalUrl` matches the original sitemap URL — redirecting sitemap entries should be updated)
- [ ] No conflicting robots directives (meta robots tag and X-Robots-Tag header should not give contradictory instructions, e.g., one says "index" while the other says "noindex")
