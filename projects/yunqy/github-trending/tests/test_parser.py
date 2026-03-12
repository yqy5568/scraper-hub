from pathlib import Path

from projects.yunqy.github_trending.parser import parse_trending_page

FIXTURES = Path(__file__).parent / "fixtures"


def test_parse_trending_normal():
    html = (FIXTURES / "trending_sample.html").read_text()
    repos = parse_trending_page(html)

    assert len(repos) == 2
    assert repos[0]["full_name"] == "openai/tiktoken"
    assert repos[0]["language"] == "Python"
    assert repos[1]["full_name"] == "vercel/next.js"


def test_parse_trending_empty():
    repos = parse_trending_page("<html><body></body></html>")
    assert repos == []
