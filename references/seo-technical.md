# SEO Technical

## Source
Google Search Central, web.dev, web.dev/vitals
Last reviewed: 2026-03-05

## Checks

### CRITICAL
- [ ] robots.txt exists at /robots.txt and returns 200 (check via Playwright)
- [ ] robots.txt does not block important pages (no blanket Disallow: /)
- [ ] XML sitemap exists (check /sitemap.xml or reference in robots.txt)
- [ ] All internal links return 200 (no broken links — check via Playwright navigation)
- [ ] HTTPS on all pages (no mixed content, no http:// internal links)
- [ ] Mobile viewport meta tag present: <meta name="viewport" content="width=device-width, initial-scale=1">
- [ ] Core Web Vitals pass (run pagespeed.sh): LCP < 2.5s, INP < 200ms, CLS < 0.1 — **CONDITIONAL: if PageSpeed API fails (429/quota), mark as UNTESTABLE and exclude from score denominator.**

### IMPORTANT
- [ ] Canonical tag present on every page (<link rel="canonical">)
- [ ] Sitemap is valid XML and referenced in robots.txt (Sitemap: directive)
- [ ] No duplicate title tags across pages
- [ ] No duplicate meta descriptions across pages
- [ ] Pages load in under 3 seconds (Lighthouse performance score >= 50) — **CONDITIONAL: if PageSpeed API fails, mark as UNTESTABLE and exclude from score denominator.**
- [ ] No redirect chains (direct 301/302 only, no chains of 3+)

### NICE TO HAVE
- [ ] llms.txt file exists at /llms.txt (new standard — like robots.txt but for AI crawlers, tells AI models where best content is; 844K+ sites have adopted it including Anthropic, Cloudflare, Stripe)
- [ ] Lighthouse performance score >= 90 — **CONDITIONAL: if PageSpeed API fails, mark as UNTESTABLE and exclude from score denominator.**
- [ ] Lighthouse accessibility score >= 90 — **CONDITIONAL: if PageSpeed API fails, mark as UNTESTABLE and exclude from score denominator.**
- [ ] hreflang tags present if site has multiple languages — **CONDITIONAL: only check if site serves content in 2+ languages. Mark N/A for single-language sites.**
- [ ] 404 page exists and returns proper 404 status code
