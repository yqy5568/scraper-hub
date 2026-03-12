import json
from pathlib import Path

import pytest

FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture
def fixtures_dir():
    return FIXTURES_DIR


@pytest.fixture
def load_fixture():
    def _load(filename: str):
        filepath = FIXTURES_DIR / filename
        if filepath.suffix == ".json":
            return json.loads(filepath.read_text(encoding="utf-8"))
        return filepath.read_text(encoding="utf-8")
    return _load
