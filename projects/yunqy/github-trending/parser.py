"""GitHub Trending 页面解析工具"""

from __future__ import annotations


def parse_trending_page(html: str) -> list[dict]:
    try:
        from bs4 import BeautifulSoup
    except ImportError as e:
        raise ImportError("需要安装 beautifulsoup4: pip install beautifulsoup4") from e

    soup = BeautifulSoup(html, "html.parser")
    repos = []

    for article in soup.select("article.Box-row"):
        name_el = article.select_one("h2 a")
        if not name_el:
            continue

        full_name = name_el.get("href", "").strip("/")
        if not full_name or "/" not in full_name:
            continue

        desc_el = article.select_one("p")
        lang_el = article.select_one("[itemprop='programmingLanguage']")

        repo = {
            "full_name": full_name,
            "owner": full_name.split("/")[0],
            "name": full_name.split("/")[1] if "/" in full_name else full_name,
            "description": desc_el.text.strip() if desc_el else "",
            "language": lang_el.text.strip() if lang_el else "",
        }
        repos.append(repo)

    return repos
