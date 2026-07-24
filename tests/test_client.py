"""Unit tests for :mod:`confluence_integration.client`."""

from __future__ import annotations

from typing import Any
from unittest.mock import MagicMock

import pytest

from confluence_integration.client import (
    AuthenticationError,
    ConfluenceAPIError,
    ConfluenceClient,
)


def _mk_response(status: int = 200, payload: Any = None, headers: dict | None = None):
    resp = MagicMock()
    resp.status_code = status
    resp.ok = 200 <= status < 300
    resp.headers = headers or {}
    resp.json.return_value = payload if payload is not None else {}
    resp.text = "" if payload is None else str(payload)
    return resp


def test_fetch_page_content_hits_expected_endpoint(settings):
    session = MagicMock()
    session.request.return_value = _mk_response(200, {"id": "42", "title": "Hi"})
    client = ConfluenceClient(settings, session=session)

    page = client.fetch_page_content("42")

    assert page == {"id": "42", "title": "Hi"}
    call = session.request.call_args
    assert call.args == ("GET", "https://example.atlassian.net/wiki/rest/api/content/42")
    assert call.kwargs["params"]["expand"] == "body.storage,version,ancestors,space"


def test_get_child_pages_follows_pagination(settings):
    session = MagicMock()
    page1 = {
        "results": [{"id": "1"}, {"id": "2"}],
        "size": 2,
        "limit": 2,
    }
    page2 = {
        "results": [{"id": "3"}],
        "size": 1,
        "limit": 2,
    }
    session.request.side_effect = [
        _mk_response(200, page1),
        _mk_response(200, page2),
    ]
    client = ConfluenceClient(settings, session=session)

    children = client.get_child_pages("100")

    assert [c["id"] for c in children] == ["1", "2", "3"]
    assert session.request.call_count == 2
    second_call = session.request.call_args_list[1]
    assert second_call.kwargs["params"]["start"] == 2


def test_auth_error_raises(settings):
    session = MagicMock()
    session.request.return_value = _mk_response(401, {"message": "nope"})
    client = ConfluenceClient(settings, session=session)

    with pytest.raises(AuthenticationError):
        client.fetch_page_content("42")


def test_rate_limit_is_retried(settings, monkeypatch):
    sleeps: list[float] = []
    monkeypatch.setattr("confluence_integration.client.time.sleep", sleeps.append)

    session = MagicMock()
    session.request.side_effect = [
        _mk_response(429, headers={"Retry-After": "0"}),
        _mk_response(200, {"id": "42"}),
    ]
    client = ConfluenceClient(settings, session=session)

    result = client.fetch_page_content("42")

    assert result == {"id": "42"}
    assert session.request.call_count == 2
    assert sleeps == [0.0]


def test_retries_exhausted_raises(settings, monkeypatch):
    monkeypatch.setattr("confluence_integration.client.time.sleep", lambda _s: None)
    session = MagicMock()
    session.request.return_value = _mk_response(500)
    client = ConfluenceClient(settings, session=session)

    with pytest.raises(ConfluenceAPIError):
        client.fetch_page_content("42")

    # max_retries=2 → 3 total attempts (initial + 2 retries)
    assert session.request.call_count == 3


def test_search_pages_builds_cql(settings):
    session = MagicMock()
    session.request.return_value = _mk_response(200, {"results": [{"id": "9"}]})
    client = ConfluenceClient(settings, session=session)

    hits = client.search_pages("rapid recovery", ancestor_id="1000", limit=10)

    assert hits == [{"id": "9"}]
    params = session.request.call_args.kwargs["params"]
    assert params["cql"] == 'text ~ "rapid recovery" AND type = "page" AND ancestor = 1000'
    assert params["limit"] == 10
