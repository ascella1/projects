"""
포트폴리오 샘플: GitHub Trending 저장소 크롤러
- 실전 예시: 특정 페이지에서 원하는 데이터(제목, 설명, 스타 수 등)를 자동 수집 → CSV로 저장
- 크몽 의뢰 예시로 치환 가능: 쇼핑몰 상품 목록, 부동산 매물, 채용공고, 경쟁사 가격 모니터링 등
"""

import requests
from bs4 import BeautifulSoup
import pandas as pd
import time


def scrape_github_trending(language: str = "", since: str = "daily") -> pd.DataFrame:
    url = f"https://github.com/trending/{language}?since={since}"
    headers = {"User-Agent": "Mozilla/5.0 (portfolio-demo-scraper)"}

    resp = requests.get(url, headers=headers, timeout=10)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")

    rows = []
    for article in soup.select("article.Box-row"):
        name_tag = article.select_one("h2 a")
        if not name_tag:
            continue
        repo_name = name_tag.get("href", "").strip("/")

        desc_tag = article.select_one("p")
        description = desc_tag.get_text(strip=True) if desc_tag else ""

        stars_tag = article.select_one('a[href$="/stargazers"]')
        stars = stars_tag.get_text(strip=True) if stars_tag else "0"

        lang_tag = article.select_one('[itemprop="programmingLanguage"]')
        lang = lang_tag.get_text(strip=True) if lang_tag else ""

        rows.append({
            "repo": repo_name,
            "description": description,
            "stars_total": stars,
            "language": lang,
            "url": f"https://github.com/{repo_name}",
        })

    return pd.DataFrame(rows)


if __name__ == "__main__":
    df = scrape_github_trending()
    print(f"수집된 저장소 수: {len(df)}")
    print(df.head(10).to_string(index=False))
    df.to_csv("github_trending_result.csv", index=False, encoding="utf-8-sig")
    print("\n결과가 github_trending_result.csv 로 저장되었습니다.")
