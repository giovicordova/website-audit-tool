// JS Extraction Function for Website Audit Skill
// Used by SKILL.md via browser_evaluate on every crawled page.
// IMPORTANT: This MUST be an arrow function, NOT an IIFE.
// Playwright MCP rejects self-invoking functions.

// Pass as arrow function, NOT IIFE -- Playwright MCP rejects self-invoking functions
() => {
  const title = document.title || '';
  const metaDesc = document.querySelector('meta[name="description"]');
  const canonical = document.querySelector('link[rel="canonical"]');
  const viewport = document.querySelector('meta[name="viewport"]');

  // JSON-LD blocks
  const jsonLdScripts = [...document.querySelectorAll('script[type="application/ld+json"]')];
  const jsonLd = jsonLdScripts.map(s => { try { return JSON.parse(s.textContent); } catch { return null; } }).filter(Boolean);

  // Headings
  const headings = [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')].map(h => ({
    tag: h.tagName.toLowerCase(),
    text: h.textContent.trim()
  }));

  // H1 quick access
  const h1Elements = document.querySelectorAll('h1');

  // Images
  const images = [...document.querySelectorAll('img')].map(img => ({
    src: img.src,
    alt: img.alt || '',
    hasAlt: img.hasAttribute('alt'),
    altIsDescriptive: img.alt && !(/^(img|image|photo|picture|screenshot)[\s_-]?\d*/i.test(img.alt))
  }));

  // Links
  const allLinks = [...document.querySelectorAll('a[href]')];
  const origin = window.location.origin;
  const internalLinks = allLinks.filter(a => a.href.startsWith(origin)).map(a => ({
    href: a.href.replace(origin, ''),
    text: a.textContent.trim()
  }));
  const externalLinks = allLinks.filter(a => !a.href.startsWith(origin) && a.href.startsWith('http')).map(a => ({
    href: a.href,
    text: a.textContent.trim(),
    hasTargetBlank: a.target === '_blank',
    hasNoopener: (a.rel || '').includes('noopener')
  }));

  // Body text
  const bodyText = document.body.innerText || '';
  const bodyWords = bodyText.split(/\s+/).filter(w => w.length > 0);

  // First paragraph
  const firstP = document.querySelector('main p, article p, .content p, p');

  // FAQ detection
  const hasFAQ = headings.some(h => /\?$/.test(h.text)) ||
    !!document.querySelector('[itemtype*="FAQPage"]') ||
    jsonLd.some(j => j['@type'] === 'FAQPage' || (Array.isArray(j['@type']) && j['@type'].includes('FAQPage')));

  // Time tags
  const timeTags = [...document.querySelectorAll('time')].map(t => ({
    datetime: t.getAttribute('datetime') || '',
    text: t.textContent.trim()
  }));

  // OG and Twitter meta
  const ogTags = {};
  document.querySelectorAll('meta[property^="og:"]').forEach(m => {
    ogTags[m.getAttribute('property')] = m.content;
  });
  const twitterTags = {};
  document.querySelectorAll('meta[name^="twitter:"]').forEach(m => {
    twitterTags[m.getAttribute('name')] = m.content;
  });

  // HTTP links (mixed content check)
  const httpLinks = allLinks.filter(a => a.href.startsWith('http://')).map(a => a.href);

  // Tables and lists
  const tableCount = document.querySelectorAll('table').length;
  const listCount = document.querySelectorAll('ul, ol').length;

  return {
    url: window.location.href,
    title,
    titleLength: title.length,
    metaDescription: metaDesc ? metaDesc.content : null,
    metaDescriptionLength: metaDesc ? metaDesc.content.length : 0,
    viewport: viewport ? viewport.content : null,
    canonical: canonical ? canonical.href : null,
    jsonLd,
    headings,
    h1Text: h1Elements.length > 0 ? h1Elements[0].textContent.trim() : null,
    h1Count: h1Elements.length,
    images,
    imagesWithoutAlt: images.filter(i => !i.hasAlt).length,
    internalLinks,
    externalLinks,
    bodyWordCount: bodyWords.length,
    bodyTextLength: bodyText.length,
    bodyText: bodyText.substring(0, 3000),
    firstParagraph: firstP ? firstP.textContent.trim() : null,
    hasFAQ,
    timeTags,
    publishedDate: timeTags.length > 0 ? timeTags[0].datetime : null,
    ogTags,
    twitterTags,
    httpLinks,
    tableCount,
    listCount,
    hasTablesOrCharts: tableCount > 0
  };
}
