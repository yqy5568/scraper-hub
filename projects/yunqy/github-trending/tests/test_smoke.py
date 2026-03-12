import pytest


@pytest.mark.smoke
def test_github_trending_accessible():
    import requests
    resp = requests.get("https://github.com/trending", timeout=15)
    assert resp.status_code == 200
    assert "Box-row" in resp.text


@pytest.mark.smoke
def test_github_trending_language_filter():
    import requests
    resp = requests.get("https://github.com/trending/python?since=daily", timeout=15)
    assert resp.status_code == 200
