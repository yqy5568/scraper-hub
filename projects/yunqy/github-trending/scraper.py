"""GitHub Trending 榜单爬虫"""

from packages.core.base_scraper import BaseScraper


class GithubTrendingScraper(BaseScraper):

    def __init__(self):
        super().__init__("yunqy/github-trending")
        self.languages = self.config.get("target", {}).get(
            "languages", ["python", "javascript", "go"]
        )
        self.since = self.config.get("target", {}).get("since", "daily")

    def get_target_urls(self) -> list[str]:
        base = "https://github.com/trending"
        urls = [f"{base}?since={self.since}"]
        for lang in self.languages:
            urls.append(f"{base}/{lang}?since={self.since}")
        return urls

    def fetch(self, url: str) -> dict:
        resp = self.client.get(url)
        return {"html": resp.text, "url": url}

    def parse(self, raw_data: dict) -> list:
        from packages.core.pipeline import Pipeline

        html = raw_data["html"]
        url = raw_data["url"]
        items = self._extract_repos(html)
        for item in items:
            item["source_url"] = url
            item["since"] = self.since

        pipeline = Pipeline()
        pipeline.add_step(self._clean_numbers)
        return pipeline.run(items)

    def _extract_repos(self, html: str) -> list:
        try:
            from bs4 import BeautifulSoup
        except ImportError:
            self.logger.warning("beautifulsoup4 未安装，跳过解析")
            return []

        soup = BeautifulSoup(html, "html.parser")
        repos = []

        for article in soup.select("article.Box-row"):
            name_el = article.select_one("h2 a")
            if not name_el:
                continue

            full_name = name_el.get("href", "").strip("/")
            desc_el = article.select_one("p")
            lang_el = article.select_one("[itemprop='programmingLanguage']")
            stars_el = article.select("a.Link--muted")

            repo = {
                "full_name": full_name,
                "description": desc_el.text.strip() if desc_el else "",
                "language": lang_el.text.strip() if lang_el else "",
                "stars_today": "",
            }

            star_spans = article.select("span.d-inline-block.float-sm-right")
            if star_spans:
                repo["stars_today"] = star_spans[0].text.strip()

            repos.append(repo)

        return repos

    @staticmethod
    def _clean_numbers(items: list) -> list:
        for item in items:
            stars_text = item.get("stars_today", "")
            numbers = "".join(c for c in stars_text if c.isdigit())
            item["stars_today"] = int(numbers) if numbers else 0
        return items

    def save(self, items: list):
        if not items:
            return

        from datetime import date

        from packages.storage import FileStore

        store = FileStore("data/yunqy/github-trending")
        filename = f"trending_{date.today().isoformat()}.json"
        store.save_json({"date": date.today().isoformat(), "repos": items}, filename)
        self.logger.info(f"保存 {len(items)} 个仓库到 {filename}")


if __name__ == "__main__":
    scraper = GithubTrendingScraper()
    scraper.run()
