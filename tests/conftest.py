"""Shared pytest fixtures for the Confluence integration tests."""

from __future__ import annotations

from pathlib import Path

import pytest

from confluence_integration.config import (
    ConverterSettings,
    ExportSettings,
    HttpSettings,
    LoggingSettings,
    Settings,
)


@pytest.fixture
def settings(tmp_path: Path) -> Settings:
    return Settings(
        confluence_url="https://example.atlassian.net",
        api_email="tester@example.com",
        api_token="dummy-token",
        root_page_id="1000",
        output_directory=tmp_path,
        http=HttpSettings(max_retries=2, backoff_base=0.0, timeout=5),
        export=ExportSettings(page_size=2, max_title_length=40),
        converter=ConverterSettings(),
        logging=LoggingSettings(level="WARNING", file=None),
    )
