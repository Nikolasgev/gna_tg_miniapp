import os

import pytest
from starlette.testclient import TestClient

from app.main import app


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line(
        "markers",
        "integration: тесты с PostgreSQL (CI или RUN_INTEGRATION_TESTS=1)",
    )


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    run_integration = os.environ.get("CI") == "true" or os.environ.get(
        "RUN_INTEGRATION_TESTS",
        "",
    ).strip() in ("1", "true", "yes")
    if run_integration:
        return
    skip_integration = pytest.mark.skip(
        reason="Интеграционные тесты: задайте RUN_INTEGRATION_TESTS=1 и рабочий DATABASE_URL",
    )
    for item in items:
        if item.get_closest_marker("integration"):
            item.add_marker(skip_integration)


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)
