# Structured Data

## Source
Google Rich Results documentation (developers.google.com/search/docs/appearance/structured-data)
Last reviewed: 2026-03-09

## Checks

### CRITICAL
- [ ] JSON-LD present on every page (check: at least one `<script type="application/ld+json">` block exists)
- [ ] JSON-LD is valid JSON (check: parses without error)
- [ ] Schema @type matches page content (e.g., Article for blog posts, Product for product pages)
- [ ] `author` fields use Person or Organization type, never a plain string (check: `"author": "Jane Doe"` is FAIL — must be `"author": {"@type": "Person", "name": "Jane Doe"}`)
- [ ] Required fields present per schema type (see Per-Type Required Fields below)

### IMPORTANT
- [ ] Organization or LocalBusiness schema on homepage (with name, url, logo at minimum)
- [ ] Breadcrumb schema (BreadcrumbList) on all non-homepage pages (with itemListElement, position, name, item per crumb)
- [ ] Article schema on blog/content pages — **CONDITIONAL: only if blog posts were crawled. Mark N/A if no blog.**
- [ ] FAQPage schema present when page has FAQ content — **NOTE: as of Aug 2023, FAQ rich results only display for authoritative government and health websites. Mark as WARNING with note if site is neither.**
- [ ] Recommended fields present per schema type (see Per-Type Recommended Fields below)
- [ ] No deprecated schema types used for rich results (HowTo removed Sep 2023, WebSite SearchAction removed Nov 2024, Course Info removed Sep 2025)

### NICE TO HAVE
- [ ] Product schema on product/pricing pages — **CONDITIONAL: only if product/pricing pages exist. Mark N/A for service/portfolio sites.**
- [ ] Multiple schema types combined where appropriate (e.g., Article + BreadcrumbList)
- [ ] Image objects in schema include url, width, height
- [ ] `sameAs` links to official social profiles on Organization/Person schemas

---

## Per-Type Required Fields (Google Rich Results)

These are the fields Google **requires** for rich result eligibility. Missing any of these triggers Search Console errors.

### Article / NewsArticle / BlogPosting
**Required:** None officially, but omitting the following triggers warnings and blocks rich results:
- `author` (Person or Organization — never a string)
- `author.name`
- `headline`
- `image`
- `datePublished`

**Recommended:** `author.url`, `dateModified`

### Organization
**Required:** None
**Recommended:** `name`, `url`, `logo` (min 112x112px), `description`, `sameAs`, `contactPoint`

### LocalBusiness
**Required:** `name`, `address` (PostalAddress with `streetAddress`, `addressLocality`, `addressRegion`, `postalCode`, `addressCountry`)
**Recommended:** `geo` (GeoCoordinates), `url`, `telephone`, `openingHoursSpecification`

### Product (product snippet / non-purchasable)
**Required:** `name`, plus at least ONE of: `review`, `aggregateRating`, or `offers`
**Recommended:** `offers.price`, `offers.priceCurrency` (ISO 4217), `offers.availability`

### Product (merchant listing / purchasable)
**Required:** `name`, `image`, `offers`, `offers.price`, `offers.priceCurrency`
**Recommended:** `brand.name`, `description`, `gtin`/`isbn`/`mpn`/`sku`, `offers.availability`, `offers.hasMerchantReturnPolicy`, `offers.shippingDetails`

### FAQPage
**Required:** `mainEntity` (array of Question), `Question.name`, `Question.acceptedAnswer` (Answer), `Answer.text`
**Note:** Rich results restricted to government/health sites since Aug 2023.

### BreadcrumbList
**Required:** `itemListElement` (array of ListItem), `ListItem.position`, `ListItem.name`, `ListItem.item` (URL — can omit on final crumb only)

### Review
**Required:** `author` (Person or Organization, name under 100 chars), `reviewRating.ratingValue`, `itemReviewed`, `itemReviewed.name`
**Recommended:** `datePublished`, `reviewRating.bestRating`, `reviewRating.worstRating`
**Note:** Self-serving reviews (business reviewing itself) are ineligible for star display on LocalBusiness/Organization.

### AggregateRating
**Required:** `ratingValue`, at least one of `ratingCount` or `reviewCount`, `itemReviewed`, `itemReviewed.name`
**Recommended:** `bestRating`, `worstRating`

### Event
**Required:** `name`, `startDate` (ISO 8601 with timezone), `location` (Place with `location.name` and `location.address`)
**Recommended:** `description`, `endDate`, `image`, `offers`, `organizer`, `performer`, `eventAttendanceMode`
**Note:** Online events use VirtualLocation; hybrid uses MixedEventAttendanceMode.

### VideoObject
**Required:** `name`, `thumbnailUrl`, `uploadDate` (ISO 8601)
**Recommended:** `contentUrl` or `embedUrl` (at least one needed for indexing), `description`, `duration`

### SoftwareApplication
**Required:** `name`, `offers.price` (set to 0 if free), plus at least ONE of: `aggregateRating` or `review`
**Recommended:** `applicationCategory`, `operatingSystem`, `offers.priceCurrency`

### Course
**Required:** `name`, `description` (display limit 60 chars)
**Recommended:** `provider` (Organization)
**Note:** Course Info variant deprecated Sep 2025. Basic Course list still supported, needs 3+ courses for carousel.

### Recipe — CONDITIONAL: only check if recipe pages exist
**Required:** `name`, `image` (multiple aspect ratios recommended: 16x9, 4x3, 1x1)
**Recommended:** `author` (Person/Organization, not string), `recipeIngredient`, `recipeInstructions`, `cookTime`, `prepTime`, `totalTime`

### Person (via ProfilePage)
**Required:** `ProfilePage.mainEntity` (Person), `Person.name`
**Recommended:** `description`, `image`, `sameAs` (external profile URLs), `alternateName`

---

## Deprecated Rich Result Types (do not rely on)

| Type | Removed | Notes |
|------|---------|-------|
| HowTo | Sep 2023 | Fully removed from mobile + desktop |
| FAQPage | Aug 2023 | Restricted to government/health only |
| WebSite + SearchAction | Nov 2024 | Sitelinks search box removed globally |
| Course Info (CourseInstance) | Sep 2025 | Basic Course list still works |
| Estimated Salary | Sep 2025 | |
| Practice Problem | Jan 2026 | |

## Required Extraction Fields
- jsonLd — All structured data checks (presence, validity, @type matching, required fields, deprecated types)

## Changelog

### 2026-03-09
- Added per-type required/recommended fields for all Google rich result types
- Added deprecated rich result types table
- Last reviewed date updated

### 2026-03-05
- Initial version — sourced from Google Rich Results documentation (developers.google.com/search/docs/appearance/structured-data)
