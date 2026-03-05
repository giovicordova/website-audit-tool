# Structured Data

## Source
Schema.org specification, Google Rich Results documentation
Last reviewed: 2026-03-05

## Checks

### CRITICAL
- [ ] JSON-LD present on every page (check: at least one <script type="application/ld+json"> block exists)
- [ ] JSON-LD is valid JSON (check: parses without error)
- [ ] Schema @type matches page content (e.g., Article for blog posts, Product for product pages, FAQPage for FAQ sections)

### IMPORTANT
- [ ] Organization or LocalBusiness schema on homepage (with name, url, logo at minimum)
- [ ] Breadcrumb schema (BreadcrumbList) on all non-homepage pages
- [ ] Article schema on blog/content pages (with headline, author, datePublished, dateModified) — **CONDITIONAL: only check if blog posts were crawled. Mark N/A if site has no blog or no blog post was reachable.**
- [ ] FAQPage schema present when page has FAQ content
- [ ] No schema validation errors (check: required properties present per schema.org spec)

### NICE TO HAVE
- [ ] Product schema on product/pricing pages (with name, description, offers) — **CONDITIONAL: only check if product/pricing pages exist. Mark N/A for service/portfolio sites.**
- [ ] WebSite schema with SearchAction on homepage (sitelinks search box)
- [ ] Multiple schema types combined where appropriate (e.g., Article + BreadcrumbList + FAQPage)
- [ ] Image objects in schema include url, width, height
