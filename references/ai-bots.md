# AI Crawler Bots

## Source
OpenAI platform docs, Anthropic docs, Google Search Central, Perplexity docs, Apple developer docs, Meta developer docs, Amazon developer docs, ByteDance docs
Last reviewed: 2026-03-12

## Training Bots

| Bot Name | Provider | Purpose | Docs |
|---|---|---|---|
| GPTBot | OpenAI | Collects data for model training | https://platform.openai.com/docs/bots |
| ClaudeBot | Anthropic | Collects data for Claude training | https://docs.anthropic.com |
| Google-Extended | Google | Training data for Gemini/Bard | https://developers.google.com/search/docs/crawling-indexing/google-common-crawlers |
| GoogleOther | Google | Additional Google AI training | https://developers.google.com/search/docs/crawling-indexing/google-common-crawlers |
| Applebot-Extended | Apple | Extended Apple AI training | https://support.apple.com/en-us/111042 |
| Meta-ExternalAgent | Meta | Meta AI training data | https://developers.facebook.com/docs/sharing/bot |
| Bytespider | ByteDance | TikTok/ByteDance AI training | — |

## Retrieval Bots

| Bot Name | Provider | Purpose | Docs |
|---|---|---|---|
| OAI-SearchBot | OpenAI | Real-time search indexing | https://platform.openai.com/docs/bots |
| ChatGPT-User | OpenAI | Fetches pages during conversations | https://platform.openai.com/docs/bots |
| Claude-SearchBot | Anthropic | Indexes content for search | https://docs.anthropic.com |
| Claude-User | Anthropic | Fetches pages during conversations | https://docs.anthropic.com |
| PerplexityBot | Perplexity | Indexes for answer engine | https://docs.perplexity.ai/guides/bots |
| Perplexity-User | Perplexity | Real-time page fetching | https://docs.perplexity.ai/guides/bots |
| Amazonbot | Amazon | Alexa/Amazon search | https://developer.amazon.com/amazonbot |

## Legacy Names

| Legacy Name | Current Name | Notes |
|---|---|---|
| Claude-Web | Claude-User | Some sites still use the old name; treat as equivalent |

## Strategy Grading

| Grade | Criteria |
|---|---|
| A | Training bots blocked, retrieval bots allowed, no major bots unaddressed |
| B | Most bots addressed, 1-2 unaddressed |
| C | Some bots addressed but significant gaps or inconsistencies |
| D | Only 1-2 bots addressed, most unaddressed |
| F | No AI bot rules in robots.txt at all |

This grade is **informational only** — it is NOT part of the weighted overall score.

## Changelog

### 2026-03-12
- Extracted from inline SKILL.md table into standalone reference file
- Added documentation URLs for each bot
- Added legacy names section

### 2026-03-05
- Initial bot list compiled from provider documentation
