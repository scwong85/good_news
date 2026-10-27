import pytest

from ingestion.urls import InvalidURL, canonicalize_url


@pytest.mark.parametrize(
    "raw,expected",
    [
        (
            "https://Example.com/a/b/?utm_source=x&id=2&fbclid=z#frag",
            "https://example.com/a/b?id=2",
        ),
        ("http://example.com/story", "https://example.com/story"),
        ("https://example.com:443/story/", "https://example.com/story"),
        ("https://example.com", "https://example.com/"),
        ("https://example.com/?b=2&a=1", "https://example.com/?a=1&b=2"),
        ("https://example.com:8443/x", "https://example.com:8443/x"),
        ("  https://example.com/x?mc_cid=1&mc_eid=2  ", "https://example.com/x"),
    ],
)
def test_canonicalize(raw, expected):
    assert canonicalize_url(raw) == expected


@pytest.mark.parametrize(
    "raw", ["", "ftp://example.com/x", "javascript:alert(1)", "/relative/path", "mailto:a@b.c"]
)
def test_rejects_non_http(raw):
    with pytest.raises(InvalidURL):
        canonicalize_url(raw)


def test_idempotent():
    once = canonicalize_url("HTTP://Example.COM/a/?utm_medium=x&z=1")
    assert canonicalize_url(once) == once
