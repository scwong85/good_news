---
name: privacy-and-content-licensing
description: Privacy, copyright, takedown and content-safety requirements for the client-side Good News app.
---

# Privacy and content licensing

- Show only headline, <= 300-char feed excerpt, source, date, and a link to the original. Never fetch or store article bodies. Keep per-source licensing notes (terms review pending).
- Publishers see user requests directly (client-side fetching): identify the app clearly, cache (30 min), honor 429/Retry-After, use only publisher-provided feeds.
- No accounts, analytics, ads or server. Local-only data. Any telemetry (crash reports) is opt-in. Store data-safety form must say no data collected unless that changes.
- Takedown/contact path in the privacy policy and store listing; implement removal by disabling a source or blocklisting in the next release.
- Report-to-hide on device; blocklist/exclude rules for policy_violation (blocklist-based only; state the limitation).
