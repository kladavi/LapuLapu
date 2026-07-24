"""Configuration management for the Confluence exporter.

Secrets are loaded from ``config/.env`` (via python-dotenv) or the process
environment. Non-secret application settings are loaded from
``config/settings.yaml``. Both files are optional — environment variables
always take precedence.
"""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV_PATH = REPO_ROOT / "config" / ".env"
DEFAULT_SETTINGS_PATH = REPO_ROOT / "config" / "settings.yaml"


class ConfigError(RuntimeError):
    """Raised when required configuration is missing or invalid."""


@dataclass
class HttpSettings:
    timeout: int = 30
    max_retries: int = 5
    backoff_base: float = 1.5
    user_agent: str = "LapuLapu-Confluence-Exporter/1.0"


@dataclass
class ExportSettings:
    page_size: int = 100
    include_attachment_metadata: bool = False
    max_title_length: int = 80
    manifest_filename: str = "export-manifest.json"


@dataclass
class ConverterSettings:
    body_width: int = 0
    ignore_links: bool = False
    ignore_images: bool = False
    bypass_tables: bool = False
    strip_layout_macros: bool = True


@dataclass
class LoggingSettings:
    level: str = "INFO"
    file: str | None = "logs/confluence-export.log"


@dataclass
class Settings:
    """Aggregate settings resolved from env + yaml."""

    confluence_url: str
    api_email: str
    api_token: str
    root_page_id: str
    output_directory: Path
    http: HttpSettings = field(default_factory=HttpSettings)
    export: ExportSettings = field(default_factory=ExportSettings)
    converter: ConverterSettings = field(default_factory=ConverterSettings)
    logging: LoggingSettings = field(default_factory=LoggingSettings)

    @property
    def api_base(self) -> str:
        """Base URL for REST API calls (with trailing '/wiki/rest/api')."""
        return self.confluence_url.rstrip("/") + "/wiki/rest/api"

    @property
    def wiki_base(self) -> str:
        """Base URL for user-facing wiki links."""
        return self.confluence_url.rstrip("/") + "/wiki"


def _coerce_bool(value: Any, default: bool) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    if not isinstance(data, dict):
        raise ConfigError(f"{path} did not parse to a mapping")
    return data


def load_settings(
    env_path: Path | str | None = None,
    settings_path: Path | str | None = None,
    *,
    require_credentials: bool = True,
) -> Settings:
    """Load settings from disk + environment.

    Parameters
    ----------
    env_path:
        Path to a ``.env`` file. Defaults to ``config/.env`` at repo root.
    settings_path:
        Path to the YAML settings file. Defaults to ``config/settings.yaml``.
    require_credentials:
        When ``True`` (default) raise :class:`ConfigError` if
        ``API_EMAIL``/``API_TOKEN`` are missing. Set ``False`` for dry-run
        mode where the client is never invoked.
    """
    env_file = Path(env_path) if env_path else DEFAULT_ENV_PATH
    settings_file = Path(settings_path) if settings_path else DEFAULT_SETTINGS_PATH

    if env_file.exists():
        load_dotenv(env_file, override=False)

    raw = _load_yaml(settings_file)

    confluence_url = os.getenv("CONFLUENCE_URL", "").strip()
    api_email = os.getenv("API_EMAIL", "").strip()
    api_token = os.getenv("API_TOKEN", "").strip()
    root_page_id = os.getenv("ROOT_PAGE_ID", "").strip()
    output_directory = os.getenv("OUTPUT_DIRECTORY", "./exports").strip()

    if not confluence_url:
        raise ConfigError(
            "CONFLUENCE_URL is not set. Copy config/.env.example to config/.env "
            "and fill in real values, or export it in the environment."
        )
    if require_credentials and (not api_email or not api_token):
        raise ConfigError(
            "API_EMAIL and API_TOKEN must be set for authenticated API calls."
        )
    if not root_page_id:
        raise ConfigError("ROOT_PAGE_ID is not set.")

    http_raw = raw.get("http", {}) or {}
    export_raw = raw.get("export", {}) or {}
    converter_raw = raw.get("converter", {}) or {}
    logging_raw = raw.get("logging", {}) or {}

    http_cfg = HttpSettings(
        timeout=int(http_raw.get("timeout", HttpSettings.timeout)),
        max_retries=int(http_raw.get("max_retries", HttpSettings.max_retries)),
        backoff_base=float(http_raw.get("backoff_base", HttpSettings.backoff_base)),
        user_agent=str(http_raw.get("user_agent", HttpSettings.user_agent)),
    )
    export_cfg = ExportSettings(
        page_size=int(export_raw.get("page_size", ExportSettings.page_size)),
        include_attachment_metadata=_coerce_bool(
            export_raw.get("include_attachment_metadata"),
            ExportSettings.include_attachment_metadata,
        ),
        max_title_length=int(
            export_raw.get("max_title_length", ExportSettings.max_title_length)
        ),
        manifest_filename=str(
            export_raw.get("manifest_filename", ExportSettings.manifest_filename)
        ),
    )
    converter_cfg = ConverterSettings(
        body_width=int(converter_raw.get("body_width", ConverterSettings.body_width)),
        ignore_links=_coerce_bool(
            converter_raw.get("ignore_links"), ConverterSettings.ignore_links
        ),
        ignore_images=_coerce_bool(
            converter_raw.get("ignore_images"), ConverterSettings.ignore_images
        ),
        bypass_tables=_coerce_bool(
            converter_raw.get("bypass_tables"), ConverterSettings.bypass_tables
        ),
        strip_layout_macros=_coerce_bool(
            converter_raw.get("strip_layout_macros"),
            ConverterSettings.strip_layout_macros,
        ),
    )
    logging_cfg = LoggingSettings(
        level=str(logging_raw.get("level", LoggingSettings.level)).upper(),
        file=logging_raw.get("file", LoggingSettings.file),
    )

    output_path = Path(output_directory)
    if not output_path.is_absolute():
        output_path = (REPO_ROOT / output_path).resolve()

    return Settings(
        confluence_url=confluence_url,
        api_email=api_email,
        api_token=api_token,
        root_page_id=root_page_id,
        output_directory=output_path,
        http=http_cfg,
        export=export_cfg,
        converter=converter_cfg,
        logging=logging_cfg,
    )


def configure_logging(settings: Settings) -> logging.Logger:
    """Configure and return the package logger based on settings."""
    logger = logging.getLogger("confluence_integration")
    if logger.handlers:
        return logger  # already configured

    level = getattr(logging, settings.logging.level, logging.INFO)
    logger.setLevel(level)

    formatter = logging.Formatter(
        "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )

    stderr_handler = logging.StreamHandler()
    stderr_handler.setFormatter(formatter)
    logger.addHandler(stderr_handler)

    if settings.logging.file:
        file_path = Path(settings.logging.file)
        if not file_path.is_absolute():
            file_path = REPO_ROOT / file_path
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_handler = logging.FileHandler(file_path, encoding="utf-8")
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    logger.propagate = False
    return logger
