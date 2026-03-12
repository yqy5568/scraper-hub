---
owner: yunqy
target: GitHub Trending
status: running
created: 2026-03-11
description: 抓取 GitHub Trending 榜单，按语言/时间维度归档
schedule: "0 8 * * *"
---

# github-trending

抓取 GitHub Trending 页面，按语言分类采集热门仓库信息。

## 采集字段

- 仓库全名 (owner/name)
- 描述
- 编程语言
- 今日 Star 增长数

## 使用

```bash
make run owner=yunqy name=github-trending
```

## 测试

```bash
make test-project owner=yunqy name=github-trending
```
