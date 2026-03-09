---
name: lighthouse-runner
model: haiku
description: Runs Lighthouse CLI and returns performance scores + Core Web Vitals. Launched by the website-audit skill during audits.
tools: Bash, Read
background: true
---

Run `scripts/lighthouse.sh {url}` where {url} is the URL provided in your prompt.

If the script exits non-zero or returns an error JSON, return:
{"error": "Lighthouse run failed", "details": "<stderr output>"}

If successful, return the JSON output exactly as produced by the script. Do not summarize or reformat.
