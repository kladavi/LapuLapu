"""Confluence integration package for the Lapu-Lapu knowledge vault.

Public API:

    from confluence_integration import (
        ConfluenceClient,
        ConfluenceExporter,
        Settings,
        load_settings,
    )
"""

from .client import ConfluenceClient, ConfluenceAPIError, AuthenticationError
from .converter import HtmlToMarkdownConverter
from .exporter import ConfluenceExporter, ExportManifest
from .config import Settings, load_settings

__all__ = [
    "ConfluenceClient",
    "ConfluenceAPIError",
    "AuthenticationError",
    "HtmlToMarkdownConverter",
    "ConfluenceExporter",
    "ExportManifest",
    "Settings",
    "load_settings",
]

__version__ = "1.0.0"
