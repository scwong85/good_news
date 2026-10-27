"""URL canonicalization used for idempotent ingestion and duplicate detection."""

from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

TRACKING_PARAMS = {
    "fbclid",
    "gclid",
    "dclid",
    "msclkid",
    "mc_cid",
    "mc_eid",
    "igshid",
    "mkt_tok",
    "_hsenc",
    "_hsmi",
    "ref_src",
    "ref_url",
    "yclid",
    "oly_enc_id",
    "oly_anon_id",
}
TRACKING_PREFIXES = ("utm_", "pk_", "vero_", "hsa_")


class InvalidURL(ValueError):
    pass


def canonicalize_url(url: str) -> str:
    """Return a stable form of `url`, or raise InvalidURL for non-HTTP(S) / hostless URLs.

    - scheme: http is upgraded to https; host lowercased; default ports dropped
    - fragment and tracking parameters removed; remaining parameters sorted
    - trailing slash removed except for the root path
    """
    url = (url or "").strip()
    parts = urlsplit(url)
    if parts.scheme.lower() not in {"http", "https"} or not parts.hostname:
        raise InvalidURL(f"unsupported URL: {url!r}")
    host = parts.hostname.lower().rstrip(".")
    try:
        port = parts.port
    except ValueError:
        raise InvalidURL(f"invalid port: {url!r}") from None
    netloc = host if port in (None, 80, 443) else f"{host}:{port}"
    query = [
        (k, v)
        for k, v in parse_qsl(parts.query, keep_blank_values=True)
        if k.lower() not in TRACKING_PARAMS and not k.lower().startswith(TRACKING_PREFIXES)
    ]
    path = parts.path or "/"
    if len(path) > 1:
        path = path.rstrip("/") or "/"
    return urlunsplit(("https", netloc, path, urlencode(sorted(query)), ""))
