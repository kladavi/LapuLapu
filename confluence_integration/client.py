"""Thin, retry-aware HTTP client for the Confluence Cloud REST API.

The client exposes the three endpoints required by the exporter:

- ``GET /wiki/rest/api/content/{id}``      → :meth:`fetch_page_content`
- ``GET /wiki/rest/api/content/{id}/child/page`` → :meth:`get_child_pages`
- ``GET /wiki/rest/api/content/search``    → :meth:`search_pages`

Authentication is HTTP Basic (email + API token). Rate limits (HTTP 429)
and transient 5xx errors are retried with exponential backoff.
"""

from __future__ import annotations

import logging
import time
from typing import Any, Iterator

import requests
from requests.auth import HTTPBasicAuth

from .config import Settings

logger = logging.getLogger("confluence_integration.client")


class ConfluenceAPIError(RuntimeError):
    """Raised for non-recoverable API errors."""

    def __init__(self, message: str, status_code: int | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code


class AuthenticationError(ConfluenceAPIError):
    """Raised when the Confluence API returns 401 or 403."""


class ConfluenceClient:
    """Retry-aware Confluence Cloud REST client.

    Parameters
    ----------
    settings:
        Loaded :class:`~confluence_integration.config.Settings`.
    session:
        Optional pre-configured ``requests.Session``. Injecting a session
        makes unit-testing with :mod:`requests_mock` or manual mocking
        straightforward.
    """

    def __init__(
        self,
        settings: Settings,
        session: requests.Session | None = None,
    ) -> None:
        self.settings = settings
        self.session = session or requests.Session()
        self.session.auth = HTTPBasicAuth(settings.api_email, settings.api_token)
        self.session.headers.update(
            {
                "Accept": "application/json",
                "User-Agent": settings.http.user_agent,
            }
        )

    # ── Public API ─────────────────────────────────────────────────

    def validate_authentication(self) -> dict[str, Any]:
        """Confirm the credentials work by fetching the current user profile.

        Returns the parsed JSON payload on success. Raises
        :class:`AuthenticationError` on 401/403.
        """
        url = f"{self.settings.api_base}/user/current"
        return self._request("GET", url)

    def fetch_page_content(self, page_id: str) -> dict[str, Any]:
        """Fetch a single page with body storage, version, and ancestors."""
        url = f"{self.settings.api_base}/content/{page_id}"
        params = {"expand": "body.storage,version,ancestors,space"}
        return self._request("GET", url, params=params)

    def get_child_pages(self, page_id: str) -> list[dict[str, Any]]:
        """Return **all** direct child pages (materialises pagination)."""
        return list(self.iter_child_pages(page_id))

    def iter_child_pages(self, page_id: str) -> Iterator[dict[str, Any]]:
        """Yield direct child pages, transparently following pagination."""
        url = f"{self.settings.api_base}/content/{page_id}/child/page"
        params: dict[str, Any] = {
            "expand": "body.storage,version",
            "limit": self.settings.export.page_size,
            "start": 0,
        }
        while True:
            payload = self._request("GET", url, params=params)
            results = payload.get("results", []) or []
            for item in results:
                yield item
            size = payload.get("size", len(results))
            limit = payload.get("limit", params["limit"]) or params["limit"]
            if size < limit:
                return
            params["start"] = params["start"] + limit

    def search_pages(
        self,
        query: str,
        ancestor_id: str | None = None,
        *,
        limit: int = 25,
    ) -> list[dict[str, Any]]:
        """CQL search, optionally scoped under an ancestor page."""
        cql_parts = [f'text ~ "{self._escape_cql(query)}"', 'type = "page"']
        if ancestor_id:
            cql_parts.append(f"ancestor = {int(ancestor_id)}")
        url = f"{self.settings.api_base}/content/search"
        params = {
            "cql": " AND ".join(cql_parts),
            "limit": limit,
            "expand": "version,ancestors",
        }
        payload = self._request("GET", url, params=params)
        return payload.get("results", []) or []

    # ── Internals ──────────────────────────────────────────────────

    @staticmethod
    def _escape_cql(query: str) -> str:
        return query.replace('"', '\\"')

    def _request(
        self,
        method: str,
        url: str,
        *,
        params: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        max_retries = self.settings.http.max_retries
        backoff_base = self.settings.http.backoff_base
        timeout = self.settings.http.timeout

        attempt = 0
        while True:
            try:
                response = self.session.request(
                    method,
                    url,
                    params=params,
                    timeout=timeout,
                )
            except requests.RequestException as exc:
                if attempt >= max_retries:
                    raise ConfluenceAPIError(
                        f"Network error after {attempt} retries: {exc}"
                    ) from exc
                delay = backoff_base * (2 ** attempt)
                logger.warning(
                    "Network error on %s %s (attempt %d/%d): %s — sleeping %.1fs",
                    method,
                    url,
                    attempt + 1,
                    max_retries,
                    exc,
                    delay,
                )
                time.sleep(delay)
                attempt += 1
                continue

            status = response.status_code
            if status in (401, 403):
                raise AuthenticationError(
                    f"Authentication failed ({status}) for {url}: {response.text[:200]}",
                    status_code=status,
                )
            if status == 429 or 500 <= status < 600:
                if attempt >= max_retries:
                    raise ConfluenceAPIError(
                        f"Giving up on {method} {url} after {attempt} retries "
                        f"(last status {status})",
                        status_code=status,
                    )
                retry_after = response.headers.get("Retry-After")
                if retry_after:
                    try:
                        delay = float(retry_after)
                    except ValueError:
                        delay = backoff_base * (2 ** attempt)
                else:
                    delay = backoff_base * (2 ** attempt)
                logger.warning(
                    "Retryable status %d on %s %s (attempt %d/%d) — sleeping %.1fs",
                    status,
                    method,
                    url,
                    attempt + 1,
                    max_retries,
                    delay,
                )
                time.sleep(delay)
                attempt += 1
                continue
            if not response.ok:
                raise ConfluenceAPIError(
                    f"{method} {url} failed with {status}: {response.text[:500]}",
                    status_code=status,
                )
            try:
                return response.json()
            except ValueError as exc:
                raise ConfluenceAPIError(
                    f"Response from {url} was not JSON: {exc}"
                ) from exc
