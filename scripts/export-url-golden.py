#!/usr/bin/env python3
"""Write app/test/fixtures/golden_urls.json from the Python canonicalizer (the reference).

    python3 scripts/export-url-golden.py          # rewrite
    python3 scripts/export-url-golden.py --check  # exit 1 if stale
IPv6 hosts are excluded (the Python implementation drops their brackets; not supported).
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "pipeline-prototype"))
from ingestion.urls import InvalidURL, canonicalize_url  # noqa: E402

OUT = ROOT / "app" / "test" / "fixtures" / "golden_urls.json"
INPUTS = [
    "https://Example.com/a/b/?utm_source=x&id=2&fbclid=z#frag",
    "http://example.com/story",
    "https://example.com:443/story/",
    "https://example.com",
    "https://example.com/?b=2&a=1",
    "https://example.com:8443/x",
    "  https://example.com/x?mc_cid=1&mc_eid=2  ",
    "HTTP://EXAMPLE.COM/Path/To/Page/",
    "https://example.com/a//b///",
    "https://example.com////",
    "https://example.com./x",
    "https://user:pw@example.com/x",
    "https://example.com:80/x",
    "https://example.com/x?a=1&a=2&a=0",
    "https://example.com/x?flag&b=&=v",
    "https://example.com/x?q=hello+world&r=a%20b",
    "https://example.com/x?q=caf%C3%A9&r=%E2%9C%93",
    "https://example.com/x?q=100%25&bad=%zz&trail=%",
    "https://example.com/x?name=Zoë&city=München",
    "https://example.com/x?emoji=\U0001f600",
    "https://example.com/x?UTM_Source=a&Fbclid=b&keep=1",
    "https://example.com/x?pk_campaign=a&hsa_acc=b&vero_id=c&utm_term=d&z=1",
    "https://example.com/x?ref=home&source=nl",
    "https://example.com/x?a=1&&b=2&",
    "https://example.com/x#only-fragment",
    "https://example.com/p%C3%A4th/%7Euser",
    "https://m.example.com/wp/2026/10/story-title/?amp=1",
    "https://news.example.co.uk/a-b_c.d/e?x=~tilde",
    "https://example.com?x=1",
    "https://example.com#frag",
    "",
    "ftp://example.com/x",
    "javascript:alert(1)",
    "/relative/path",
    "mailto:a@b.c",
    "https://",
    "https:///nohost",
    "https://example.com:notaport/x",
    "https://example.com:99999/x",
    "example.com/no-scheme",
    "//example.com/protocol-relative",
]


def build() -> str:
    cases = []
    for raw in INPUTS:
        try:
            expected = canonicalize_url(raw)
        except InvalidURL:
            expected = None
        cases.append({"input": raw, "expected": expected})
    return json.dumps(cases, indent=1, ensure_ascii=False) + "\n"


def main() -> int:
    text = build()
    if "--check" in sys.argv:
        if not OUT.parent.exists():
            return 0
        if not OUT.exists() or OUT.read_text(encoding="utf-8") != text:
            print("app/test/fixtures/golden_urls.json is stale: run python3 scripts/export-url-golden.py")
            return 1
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUT} ({len(INPUTS)} cases)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
