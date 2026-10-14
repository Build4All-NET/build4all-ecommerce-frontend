"""Shared HTTP client for App Store Connect calls made from CI.

The App Store Connect API returns transient 5xx errors fairly regularly
(most often ``500 Internal Server Error`` on ``GET /v1/apps?filter[bundleId]=...``).
A bare ``requests.get(...)`` + ``raise_for_status()`` turns one of those blips
into a failed build, so every ASC call in CI should go through here instead.

Two sessions with different retry policies:

* reads  (GET/HEAD)          retry on 408/429/500/502/503/504
* writes (POST/PATCH/DELETE) retry on 408/429/502/503/504 only — a 500 may mean
  Apple already applied the change, and replaying it could create duplicates.

Usage — either call the helpers directly::

    import asc_http
    r = asc_http.get(f"{asc_http.BASE}/v1/apps", params={"filter[bundleId]": bundle})
    asc_http.raise_for_status(r, "look up app")

or keep existing ``requests.get(...)`` call sites and route them through the
retrying sessions with a single line at the top of the script::

    import asc_http; asc_http.install()
"""

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

BASE = "https://api.appstoreconnect.apple.com"

# (connect, read) — ASC occasionally stalls, so the read timeout is generous.
DEFAULT_TIMEOUT = (20, 90)

READ_RETRY_STATUSES = (408, 429, 500, 502, 503, 504)
# 500 is deliberately absent: a write that got a 500 may still have been applied.
WRITE_RETRY_STATUSES = (408, 429, 502, 503, 504)

_TOTAL_RETRIES = 5
_BACKOFF_FACTOR = 2  # ~2s, 4s, 8s, 16s, 32s between attempts


def _make_session(statuses, methods):
    kwargs = dict(
        total=_TOTAL_RETRIES,
        connect=_TOTAL_RETRIES,
        read=_TOTAL_RETRIES,
        status=_TOTAL_RETRIES,
        backoff_factor=_BACKOFF_FACTOR,
        status_forcelist=list(statuses),
        allowed_methods=frozenset(methods),
        respect_retry_after_header=True,
        raise_on_status=False,
    )
    try:
        retry = Retry(backoff_jitter=1.0, **kwargs)  # urllib3 >= 2.0
    except TypeError:
        retry = Retry(**kwargs)
    session = requests.Session()
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


read_session = _make_session(READ_RETRY_STATUSES, ["GET", "HEAD", "OPTIONS"])
write_session = _make_session(WRITE_RETRY_STATUSES, ["POST", "PATCH", "PUT", "DELETE"])


def _request(session, method, url, **kwargs):
    kwargs.setdefault("timeout", DEFAULT_TIMEOUT)
    return session.request(method, url, **kwargs)


def get(url, **kwargs):
    return _request(read_session, "GET", url, **kwargs)


def post(url, **kwargs):
    return _request(write_session, "POST", url, **kwargs)


def patch(url, **kwargs):
    return _request(write_session, "PATCH", url, **kwargs)


def put(url, **kwargs):
    return _request(write_session, "PUT", url, **kwargs)


def delete(url, **kwargs):
    return _request(write_session, "DELETE", url, **kwargs)


def install():
    """Point the module-level ``requests`` helpers at the retrying sessions.

    Lets an existing script keep its ``requests.get(...)`` call sites while
    gaining retries, timeouts and the shared backoff policy.
    """
    requests.get = get
    requests.post = post
    requests.patch = patch
    requests.put = put
    requests.delete = delete


def describe(response):
    """Readable one-liner for a failed ASC response, including Apple's request id."""
    parts = ["HTTP {} for {}".format(response.status_code, response.url)]
    request_id = response.headers.get("x-request-id")
    if request_id:
        parts.append("x-request-id={}".format(request_id))
    try:
        errors = response.json().get("errors") or []
    except ValueError:
        errors = []
    if errors:
        parts.append(
            "; ".join(
                filter(
                    None,
                    (
                        " ".join(
                            filter(
                                None,
                                (e.get("title"), e.get("detail"), e.get("code")),
                            )
                        )
                        for e in errors
                    ),
                )
            )
        )
    else:
        body = (response.text or "").strip()
        if body:
            parts.append(body[:500])
    return " | ".join(parts)


def raise_for_status(response, context=""):
    """Like ``Response.raise_for_status`` but with an actionable message.

    Retries have already been exhausted by the time this is reached, so the
    message says what the call was trying to do and what Apple actually said.
    """
    if response.ok:
        return response
    prefix = "App Store Connect request failed"
    if context:
        prefix += " ({})".format(context)
    raise requests.HTTPError("{}: {}".format(prefix, describe(response)), response=response)
