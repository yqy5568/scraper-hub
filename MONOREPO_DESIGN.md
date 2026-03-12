# 爬虫团队 Monorepo 设计方案

> 弹性多人团队，支持动态扩缩容

---

## 一、核心设计理念

### 按人划目录，不按项目平铺

如果每人有 5-10 个项目，N 个人就是 N×5～N×10 个项目。按项目平铺会导致：
- CODEOWNERS 每加一个项目就要改一行（维护噩梦）
- `projects/` 下几十个目录，根本分不清谁的
- 权限管理极其繁琐

**所以采用 `projects/{成员名}/` 二级结构**，一条 CODEOWNERS 通配规则管住一个人所有项目。

---

## 二、目录结构

```
scraper-hub/
├── .github/
│   ├── CODEOWNERS
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── lint.yml
│   │   └── deploy.yml
│   └── PULL_REQUEST_TEMPLATE.md
│
├── packages/                          # 公共库（团队共享，Lead 审批）
│   ├── core/
│   │   ├── base_scraper.py            # 爬虫基类
│   │   ├── base_downloader.py         # 下载器基类
│   │   ├── pipeline.py                # 数据管道
│   │   └── exceptions.py
│   ├── http/
│   │   ├── client.py                  # 统一 HTTP 客户端
│   │   ├── proxy_pool.py             # 代理池
│   │   └── fingerprint.py            # UA/指纹轮换
│   ├── anti_detect/
│   │   ├── captcha.py
│   │   ├── cookie_manager.py
│   │   └── rate_limiter.py
│   ├── storage/
│   │   ├── file_store.py
│   │   ├── s3_store.py
│   │   ├── db.py
│   │   └── export.py
│   ├── notify/
│   │   ├── dingtalk.py
│   │   ├── wechat.py
│   │   └── email.py
│   └── utils/
│       ├── logger.py
│       ├── config.py
│       ├── retry.py
│       └── dedup.py
│
├── projects/                          # ★ 按成员分目录 ★
│   │
│   ├── yunqy/                       # —— 示例：Lead 的所有项目 ——
│   │   ├── github-trending/           # GitHub Trending 榜单
│   │   │   ├── scraper.py
│   │   │   ├── config.yaml
│   │   │   ├── requirements.txt
│   │   │   └── README.md
│   │   ├── github-repos/              # GitHub 仓库信息采集
│   │   │   ├── scraper.py
│   │   │   └── ...
│   │   └── huggingface-models/        # HuggingFace 模型数据
│   │       ├── scraper.py
│   │       └── ...
│   │
│   │   # 其他成员目录通过 make add-member 自动创建
│   │
│   └── _template/                     # 新项目模板
│       ├── scraper.py
│       ├── config.yaml.example
│       ├── requirements.txt
│       ├── tests/
│       │   ├── conftest.py
│       │   ├── fixtures/              # 放接口返回样本
│       │   ├── test_parser.py
│       │   └── test_smoke.py
│       └── README.md
│
├── scripts/
│   ├── new_project.sh                 # 一键创建新项目
│   ├── check_health.py                # 全局健康检查
│   └── deploy.sh
│
├── configs/
│   ├── proxies.yaml
│   └── schedules.yaml
│
├── docs/
│   ├── onboarding.md                  # 新人上手
│   ├── coding_standards.md            # 编码规范
│   ├── anti_detect_guide.md           # 反反爬经验库
│   └── project_registry.md            # 所有项目清单（自动生成）
│
├── .env.example
├── .gitignore
├── pyproject.toml
├── requirements-base.txt
├── Makefile
└── README.md
```

**关键点**：成员要加新项目，直接在 `projects/{成员名}/` 下建目录就行，不用改 CODEOWNERS，不用找 Lead 审批。

---

## 三、团队架构

```
┌────────────────────────────────────────────────────────────────────┐
│                         Lead（技术负责人）                           │
│              packages/ 审批 · CI/CD · 全局管控 · 人员变动             │
├────────────────────────────────────────────────────────────────────┤
│  成员 1      │  成员 2      │  成员 3      │  ...  │  成员 N       │
│  若干项目     │  若干项目     │  若干项目     │       │  若干项目     │
│  自己目录     │  自己目录     │  自己目录     │       │  自己目录     │
│  全权管理     │  全权管理     │  全权管理     │       │  全权管理     │
└──────────────┴──────────────┴──────────────┴───────┴──────────────┘
```

---

## 四、权限分配

### 4.1 CODEOWNERS —— 一人一行，按需增减

```bash
# .github/CODEOWNERS

# ═══ 公共库：只有 Lead 能合并 ═══
packages/                     @lead-id

# ═══ 每人的目录：通配符一劳永逸 ═══
# 新成员入职时通过 make add-member 自动追加，离职时注释掉（不删除）
projects/yunqy/**           @lead-id
# projects/成员B/**           @成员B-github-id  @lead-id
# projects/成员C/**           @成员C-github-id  @lead-id

# ═══ 基础设施：仅 Lead ═══
.github/**                    @lead-id
scripts/**                    @lead-id
configs/**                    @lead-id

# ═══ 文档：所有人可贡献 ═══
docs/**                       @lead-id
```

**说明**：每人一行通配符，成员加入/离职时只需增减一行，无需逐项目配置。不管团队未来有 30 个还是 300 个爬虫项目，权限配置都保持简洁。

### 4.2 权限矩阵

| 操作 | 自己的 `projects/xxx/` | 别人的 `projects/yyy/` | `packages/` | `configs/` `.github/` |
|------|----------------------|----------------------|-------------|----------------------|
| 看代码 | ✅ | ✅ | ✅ | ✅ |
| 直接 push（develop） | ✅ | ❌ | ❌ | ❌ |
| 提 PR | ✅ | ✅ | ✅ | ❌ |
| 合并 PR | ✅ 自己审批 | ❌ 对方审批 | ❌ Lead 审批 | ❌ Lead 审批 |
| 建新项目目录 | ✅ 随时建 | ❌ | — | — |

### 4.3 分支保护规则

```
main（生产）
 ├── 禁止直接 push
 ├── 必须通过 PR + CODEOWNER 审批
 ├── 必须通过 CI
 └── 禁止 force push

develop（开发）
 ├── 禁止直接 push（建议，也可放开让大家直接推自己目录）
 └── PR 至少 1 人 review
```

### 4.4 实际场景

```
场景 1：成员 A 新增一个爬虫项目
  → 直接在 projects/{成员A}/ 下创建新项目目录
  → 不需要改 CODEOWNERS（通配符已覆盖）
  → 不需要找 Lead 审批
  → 自己 push，自己合并

场景 2：成员 A 改了公共 HTTP 客户端
  → 改了 packages/http/client.py
  → 提 PR → Lead review → 合并
  → CI 自动跑全量测试（公共库改动影响所有人）

场景 3：成员 B 想借鉴成员 A 的代码
  → 可以看 projects/{成员A}/ 下所有代码
  → 复制到自己目录 projects/{成员B}/ 下改 → 没问题
  → 想直接改成员 A 的代码 → 必须提 PR，成员 A 审批

场景 4：成员 B 发现成员 A 的某爬虫有 bug
  → 提 PR 修改 projects/{成员A}/{项目名}/
  → 成员 A 作为 CODEOWNER 审批后合并

场景 5：新成员入职
  → Lead 运行 make add-member name=新成员名 github=新成员GitHub用户名
  → 自动完成：创建目录、CODEOWNERS 追加、GitHub 邀请
  → 详见「人员变动管理」章节
```

---

## 五、人员变动管理

### 5.1 入职 Onboarding（3 步）

```
1. Lead 运行: make add-member name=新成员名 github=新成员GitHub用户名
   自动完成: 创建 projects/新成员名/ 目录, CODEOWNERS 追加一行, GitHub 邀请 Collaborator

2. 新成员 clone 仓库, make install

3. 新成员 make new-project 创建自己的第一个项目
```

### 5.2 离职 Offboarding（保留代码，收回权限）

```
1. Lead 运行: make offboard-member name=离职成员名
   自动完成: 
     - CODEOWNERS 中注释掉该成员行（不删除）
     - 该成员项目 README 中 status 改为 "archived"
     - GitHub 移除 Collaborator 权限
     - 代码和分支全部保留，不删除

2. 如需交接: 另一个成员接管项目，把项目移到自己目录或留在原地并更新 CODEOWNERS owner
```

### 5.3 交接 Transfer

```
场景: 成员 A 离职，成员 B 接手 A 的某个项目

方式 1: 项目留在 projects/A/ 下，CODEOWNERS 中 A 的行改成 B 的 GitHub ID
方式 2: 把项目移到 projects/B/ 下（git mv）

推荐方式 1（改动最小，保留 git 历史）
```

---

## 六、分支与工作流

### 6.1 分支命名

```
main
develop
feature/{成员名}/{项目名}-{描述}      ← 日常开发
fix/{成员名}/{项目名}-{描述}           ← Bug 修复
refactor/packages-{模块名}            ← 公共库重构

示例：
  feature/yunqy/github-trending-add-language-filter
  fix/yunqy/github-repos-login-expired
  refactor/packages-proxy-pool-v2
```

分支里带成员名，一眼就能看出是谁的、哪个项目的。

### 6.2 日常开发流程

```
  成员日常（负责若干项目）：

  1. git checkout develop && git pull
  2. git checkout -b feature/{成员名}/{项目名}-{描述}
  3. 改 projects/{成员名}/{项目名}/ 下的文件
  4. git push → 提 PR
  5. CI 只跑有改动的项目测试
  6. 自己是 CODEOWNER → 自己合并
```

### 6.3 新建项目（零审批）

```bash
# 成员要做一个新爬虫
make new-project owner={成员名} name={项目名}

# 自动完成：
# 1. cp -r projects/_template projects/{成员名}/{项目名}
# 2. 生成 config.yaml（填入项目名）
# 3. 更新 docs/project_registry.md（项目清单）
```

### 6.4 CI 智能触发（动态检测改动）

```yaml
# 只测改了的目录，不浪费资源；无需硬编码成员名
name: CI
on:
  pull_request:
    paths:
      - 'projects/**'
      - 'packages/**'

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.changes.outputs.packages }}
      project_dirs: ${{ steps.changes.outputs.project_dirs }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: 检测改动目录
        id: changes
        run: |
          # 获取 base 分支（PR 的 base 或 merge base）
          BASE="${GITHUB_BASE_REF:-main}"
          git fetch origin $BASE

          # 检测 packages/ 是否改动
          if git diff --name-only origin/$BASE...HEAD | grep -q '^packages/'; then
            echo "packages=true" >> $GITHUB_OUTPUT
          else
            echo "packages=false" >> $GITHUB_OUTPUT
          fi

          # 动态获取有改动的 projects/*/ 目录
          DIRS=$(git diff --name-only origin/$BASE...HEAD | grep '^projects/[^/]*/' | cut -d'/' -f1-2 | sort -u | tr '\n' ' ')
          echo "project_dirs=$DIRS" >> $GITHUB_OUTPUT

  test:
    needs: detect-changes
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install -e .
          pip install -r requirements-base.txt
          pip install pytest responses

      - name: Run tests
        run: |
          # packages 有改动 → 全量测试
          # 否则只测有改动的 projects/*/ 目录
          if [ "${{ needs.detect-changes.outputs.packages }}" == "true" ]; then
            pytest projects/ packages/ -m "not smoke" --tb=short -q
          else
            for dir in ${{ needs.detect-changes.outputs.project_dirs }}; do
              if [ -d "$dir" ] && [ "$dir" != "projects/_template" ]; then
                pytest "$dir" -m "not smoke" --tb=short -q || true
              fi
            done
          fi
```

**说明**：通过 `git diff` 动态检测哪些 `projects/*/` 目录有改动，无需在 CI 中硬编码成员名，新成员加入后自动生效。

---

## 七、公共库设计

### 7.1 原则

| 规则 | 说明 |
|------|------|
| ≥ 2 个项目用到 → 提取到 packages/ | 避免重复造轮子 |
| 改 packages/ 必须 Lead 审批 | 防止改坏影响全员 |
| packages/ 有变更 → 通知全员 | 在群里说一声 |
| 保持向后兼容 | 新增可以，改接口要慎重 |

### 7.2 基类示例

```python
# packages/core/base_scraper.py

from abc import ABC, abstractmethod
from packages.http.client import HttpClient
from packages.utils.logger import get_logger
from packages.utils.config import load_config

class BaseScraper(ABC):

    def __init__(self, project_name: str):
        self.name = project_name
        self.config = load_config(project_name)
        self.logger = get_logger(project_name)
        self.client = HttpClient(
            proxy_enabled=self.config.get("proxy", False),
            rate_limit=self.config.get("rate_limit", 1.0),
        )

    @abstractmethod
    def fetch(self, url: str) -> dict: ...

    @abstractmethod
    def parse(self, raw_data: dict) -> list: ...

    @abstractmethod
    def save(self, items: list): ...

    def run(self):
        self.logger.info(f"[{self.name}] 开始运行")
        try:
            urls = self.get_target_urls()
            for url in urls:
                raw = self.fetch(url)
                items = self.parse(raw)
                self.save(items)
        except Exception as e:
            self.logger.error(f"[{self.name}] 异常: {e}")
            self.notify_error(e)
        finally:
            self.logger.info(f"[{self.name}] 运行结束")
```

### 7.3 各项目使用公共库

```python
# projects/yunqy/github-trending/scraper.py

from packages.core.base_scraper import BaseScraper

class GithubTrendingScraper(BaseScraper):

    def __init__(self):
        super().__init__("yunqy/github-trending")
        self.languages = self.config.get("languages", ["python", "javascript", "go"])

    def fetch(self, url):
        return self.client.get(url)

    def parse(self, raw_data):
        # 解析 Trending 页面，提取仓库名、star、描述
        ...

    def save(self, items):
        # 存入数据库 + 导出 JSON
        ...
```

```python
# projects/yunqy/huggingface-models/scraper.py

from packages.core.base_scraper import BaseScraper

class HuggingFaceModelScraper(BaseScraper):

    def __init__(self):
        super().__init__("yunqy/huggingface-models")

    def fetch(self, url):
        return self.client.get(url, headers={"Accept": "application/json"})

    def parse(self, raw_data):
        # 解析模型列表 API，提取模型名、下载量、标签
        ...

    def save(self, items):
        ...
```

---

## 八、项目清单自动维护

每个项目的 README.md 头部必须有元信息：

```yaml
# projects/yunqy/github-trending/README.md 头部

---
owner: yunqy
target: GitHub Trending
status: running          # running / paused / deprecated / archived
created: 2026-03-01
description: 抓取 GitHub Trending 榜单，按语言/时间维度归档
schedule: "0 8 * * *"    # 每天早上8点
---
```

通过脚本自动汇总到 `docs/project_registry.md`：

```
| 负责人 | 项目 | 目标站点 | 状态 | 调度 |
|--------|------|---------|------|------|
| yunqy | github-trending | GitHub Trending | running | 每天8点 |
| yunqy | github-repos | GitHub 仓库 | running | 每小时 |
| yunqy | huggingface-models | HuggingFace 模型 | running | 每天6点 |
| ... | ... | ... | ... | ... |
```

项目多了不怕乱，一张表全看清。

---

## 九、测试体系

爬虫测试跟普通项目不一样——目标网站随时改版、接口随时变、反爬随时升级。不能只靠单元测试，需要分层。

### 9.1 测试分层

```
┌─────────────────────────────────────────────┐
│  Layer 4: 线上巡检（定时跑，发现目标站变更）    │  ← scripts/check_health.py
├─────────────────────────────────────────────┤
│  Layer 3: 冒烟测试（真实请求，少量验证）        │  ← 手动触发 / 上线前
├─────────────────────────────────────────────┤
│  Layer 2: 集成测试（Mock HTTP，验证完整流程）   │  ← CI 必跑
├─────────────────────────────────────────────┤
│  Layer 1: 单元测试（纯逻辑，不发请求）          │  ← CI 必跑
└─────────────────────────────────────────────┘
```

### 9.2 每层测什么

| 层 | 测什么 | 怎么测 | 谁跑 | 频率 |
|----|--------|--------|------|------|
| **单元测试** | parse 解析逻辑、数据清洗、去重、格式转换 | 用固定的 HTML/JSON 样本文件 | CI（每次 PR） | 每次提交 |
| **集成测试** | fetch→parse→save 完整管道 | Mock HTTP 响应（用 responses/respx 库） | CI（每次 PR） | 每次提交 |
| **冒烟测试** | 真实发 1-2 个请求，验证网站没改版 | 真实 HTTP，标记 `@pytest.mark.smoke` | 手动 / 上线前 | 上线前 |
| **线上巡检** | 爬虫还能跑吗？数据量正常吗？ | 定时任务跑 `check_health.py` | 定时调度 | 每天 |

### 9.3 项目测试目录结构

```
projects/{成员名}/{项目名}/
├── scraper.py
├── parser.py
├── config.yaml
├── requirements.txt
├── tests/                              # 测试目录
│   ├── conftest.py                     # 公共 fixture
│   ├── fixtures/                       # 样本数据（关键！）
│   │   ├── video_list_response.json    # 真实接口返回样本
│   │   ├── video_detail_response.json
│   │   └── video_page.html             # 真实页面 HTML 样本
│   ├── test_parser.py                  # 单元测试：解析逻辑
│   ├── test_pipeline.py                # 集成测试：完整管道
│   └── test_smoke.py                   # 冒烟测试：真实请求
└── README.md
```

### 9.4 单元测试示例（测 parse 逻辑）

```python
# projects/{成员名}/{项目名}/tests/test_parser.py

import json
from pathlib import Path
from {成员名}.{项目名_下划线}.parser import parse_video_list

FIXTURES = Path(__file__).parent / "fixtures"

def test_parse_video_list_normal():
    """正常数据能解析出正确字段"""
    raw = json.loads((FIXTURES / "video_list_response.json").read_text())
    items = parse_video_list(raw)

    assert len(items) > 0
    for item in items:
        assert "video_id" in item
        assert "title" in item
        assert "play_count" in item
        assert isinstance(item["play_count"], int)

def test_parse_video_list_empty():
    """空数据不报错，返回空列表"""
    items = parse_video_list({"data": {"list": []}})
    assert items == []

def test_parse_video_list_missing_fields():
    """缺少字段时跳过该条，不崩溃"""
    raw = {"data": {"list": [{"video_id": "123"}]}}  # 缺 title
    items = parse_video_list(raw)
    assert len(items) == 0  # 数据不完整，应该被过滤
```

### 9.5 集成测试示例（Mock HTTP）

```python
# projects/{成员名}/{项目名}/tests/test_pipeline.py

import json
import responses
from pathlib import Path
from {成员名}.{项目名_下划线}.scraper import VideoScraper

FIXTURES = Path(__file__).parent / "fixtures"

@responses.activate
def test_full_pipeline():
    """Mock HTTP 响应，验证 fetch→parse→save 完整链路"""
    mock_data = json.loads((FIXTURES / "video_list_response.json").read_text())
    responses.add(
        responses.GET,
        "https://api.example.com/video/list",
        json=mock_data,
        status=200,
    )

    scraper = VideoScraper()
    raw = scraper.fetch("https://api.example.com/video/list")
    items = scraper.parse(raw)

    assert len(items) > 0
    assert all("video_id" in item for item in items)

@responses.activate
def test_retry_on_failure():
    """接口 500 时自动重试"""
    responses.add(responses.GET, "https://api.example.com/video/list", status=500)
    responses.add(responses.GET, "https://api.example.com/video/list", status=500)
    responses.add(
        responses.GET,
        "https://api.example.com/video/list",
        json={"data": {"list": []}},
        status=200,
    )

    scraper = VideoScraper()
    raw = scraper.fetch("https://api.example.com/video/list")
    assert raw is not None
```

### 9.6 冒烟测试示例（真实请求，手动跑）

```python
# projects/{成员名}/{项目名}/tests/test_smoke.py

import pytest

@pytest.mark.smoke
def test_target_site_accessible():
    """验证目标站点还能访问（没被封、没改版）"""
    import requests
    resp = requests.get("https://www.example.com", timeout=10)
    assert resp.status_code == 200

@pytest.mark.smoke
def test_api_still_works():
    """验证 API 接口返回格式没变"""
    import requests
    resp = requests.get("https://api.example.com/video/list?count=1", timeout=10)
    data = resp.json()
    assert "data" in data
    assert "list" in data["data"]
```

### 9.7 公共库测试

```
packages/
├── http/
│   ├── client.py
│   └── tests/
│       ├── test_client.py          # 测重试、超时、代理切换
│       └── test_proxy_pool.py      # 测代理轮换、失效剔除
├── storage/
│   └── tests/
│       └── test_export.py          # 测 CSV/JSON 导出格式
└── utils/
    └── tests/
        ├── test_retry.py           # 测重试装饰器
        └── test_dedup.py           # 测去重逻辑
```

### 9.8 fixtures 样本数据管理

```
重要规则：
  1. 第一次开发时，真实跑一次，把接口返回存为 fixtures/*.json
  2. fixtures 提交到 Git（不是敏感数据，是结构样本）
  3. 脱敏处理 — 用户名、手机号、token 替换为假数据
  4. 网站改版时 — 更新 fixtures + 同步修改 parse 逻辑 + 更新测试
```

### 9.9 CI 中的测试配置

```yaml
# .github/workflows/ci.yml 中的测试 job

test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - uses: actions/setup-python@v5
      with:
        python-version: '3.12'

    - name: Install dependencies
      run: |
        pip install -e .
        pip install pytest responses

    - name: Run unit + integration tests
      run: |
        # 只跑单元测试和集成测试，不跑冒烟测试（冒烟测试要真实请求）
        pytest projects/ packages/ -m "not smoke" --tb=short -q

    - name: Run smoke tests (仅 main 分支合并时)
      if: github.ref == 'refs/heads/main'
      run: |
        pytest projects/ -m smoke --tb=short -q
```

### 9.10 pytest 配置

```toml
# pyproject.toml 中追加

[tool.pytest.ini_options]
testpaths = ["projects", "packages"]
markers = [
    "smoke: 冒烟测试，真实发请求（手动跑或上线前跑）",
]
addopts = "-m 'not smoke'"   # 默认不跑冒烟测试
```

---

## 十、关键配置文件内容

### 10.1 requirements-base.txt（全局基础依赖）

```txt
# HTTP
requests>=2.31.0
httpx>=0.27.0
urllib3>=2.0

# 解析
beautifulsoup4>=4.12.0
lxml>=5.0
parsel>=1.9.0

# 数据处理
pandas>=2.2.0
openpyxl>=3.1.0

# 存储
sqlalchemy>=2.0
redis>=5.0

# 反反爬
fake-useragent>=1.5
pycryptodome>=3.20

# 测试
pytest>=8.0
responses>=0.25

# 代码质量
ruff>=0.9.0
pre-commit>=4.0

# 通知
requests  # 钉钉/企微 webhook 直接用 requests

# 工具
pyyaml>=6.0
python-dotenv>=1.0
loguru>=0.7
click>=8.1          # CLI 工具
```

### 10.2 config.yaml 示例（每个项目一份）

```yaml
# projects/yunqy/github-trending/config.yaml

project:
  name: github-trending
  owner: yunqy
  description: GitHub Trending 榜单抓取

target:
  base_url: "https://github.com/trending"
  languages: ["python", "javascript", "go", "rust"]
  since: "daily"          # daily / weekly / monthly

request:
  rate_limit: 2.0         # 每秒最多 2 个请求
  timeout: 15
  proxy: false
  max_retries: 3
  headers:
    User-Agent: "Mozilla/5.0 (compatible; Scraper/1.0)"

storage:
  type: "json"            # json / csv / database
  output_dir: "./data"
  # database:
  #   url: "${DATABASE_URL}"
  #   table: "github_trending"

schedule:
  cron: "0 8 * * *"       # 每天早上 8 点
  timezone: "Asia/Shanghai"

notify:
  on_success: false
  on_failure: true
  channel: "dingtalk"     # dingtalk / wechat / email
```

### 10.3 new_project.sh 脚本

```bash
#!/bin/bash
# scripts/new_project.sh
# 用法: ./scripts/new_project.sh <owner> <project-name>

set -e

OWNER=$1
PROJECT=$2

if [ -z "$OWNER" ] || [ -z "$PROJECT" ]; then
    echo "用法: $0 <owner> <project-name>"
    echo "示例: $0 yunqy github-trending"
    exit 1
fi

TARGET="projects/$OWNER/$PROJECT"

if [ -d "$TARGET" ]; then
    echo "错误: $TARGET 已存在"
    exit 1
fi

# 确保 owner 目录存在
mkdir -p "projects/$OWNER"

# 从模板复制
cp -r projects/_template "$TARGET"

# 替换模板中的占位符
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_CMD="sed -i ''"
else
    SED_CMD="sed -i"
fi

find "$TARGET" -type f -exec $SED_CMD "s/{{OWNER}}/$OWNER/g" {} +
find "$TARGET" -type f -exec $SED_CMD "s/{{PROJECT}}/$PROJECT/g" {} +

# 重命名 config.yaml
mv "$TARGET/config.yaml.example" "$TARGET/config.yaml"

echo "项目已创建: $TARGET"
echo ""
echo "下一步:"
echo "  1. 编辑 $TARGET/config.yaml 填写目标站点信息"
echo "  2. 编辑 $TARGET/README.md 补充项目元信息"
echo "  3. 开始编写 scraper.py"
```

---

## 十一、Makefile 快捷命令

```makefile
install:
	pip install -e .
	pip install -r requirements-base.txt
	pip install pre-commit && pre-commit install

# 安装某人某项目的依赖
install-project:
	pip install -r projects/$(owner)/$(name)/requirements.txt

# 运行某人的某个项目
run:
	python -m projects.$(owner).$(name).scraper

# 从模板创建新项目（零审批）
new-project:
	cp -r projects/_template projects/$(owner)/$(name)
	@echo "项目 projects/$(owner)/$(name) 已创建"

# 新成员入职（Lead 执行）
add-member:
	@./scripts/add_member.sh $(name) $(github)

# 成员离职（Lead 执行）
offboard-member:
	@./scripts/offboard_member.sh $(name)

# ——— 测试 ———

# 跑全量测试（不含冒烟）
test:
	pytest projects/ packages/ -m "not smoke" --tb=short -q

# 跑某人的所有项目测试
test-owner:
	pytest projects/$(owner)/ -m "not smoke" --tb=short -q

# 跑某人某个项目的测试
test-project:
	pytest projects/$(owner)/$(name)/tests/ --tb=short -q

# 跑公共库测试
test-packages:
	pytest packages/ --tb=short -q

# 冒烟测试（真实请求，手动跑）
test-smoke:
	pytest projects/ -m smoke --tb=short -q

# ——— Lint ———

lint-owner:
	ruff check projects/$(owner)/

lint:
	ruff check packages/ projects/

# 生成项目清单
registry:
	python scripts/generate_registry.py > docs/project_registry.md
```

---

## 十二、.gitignore

```gitignore
# 敏感信息
.env
**/config.local.yaml
**/credentials/
**/cookies/

# 数据产出
**/data/
**/output/
**/captured/
**/downloads/
*.db
*.sqlite
*.csv
*.xlsx

# Python
__pycache__/
.pytest_cache/
*.pyc
.venv/
```

---

## 十三、敏感信息管理

| 类型 | 存放 | 说明 |
|------|------|------|
| API Key / Token | `.env`（本地）或 GitHub Secrets | 绝不入库 |
| Cookie | 各项目 `cookies/` 目录（gitignore） | 每人本地维护 |
| 代理账号密码 | 环境变量 | 统一代理池管理 |
| 数据库密码 | 环境变量或 Secret Manager | 生产用 Vault/SSM |

---

## 十四、落地步骤

```
第 1 周：搭骨架
  1. 创建 GitHub Org + 仓库
  2. 初始化目录结构（packages/ + Lead 自己的 projects/yunqy/ + _template，其他成员入职时动态创建）
  3. 配置 CODEOWNERS + 分支保护
  4. 写好 _template/

第 2 周：迁移试点
  5. Lead 先把一个现有项目迁到 projects/yunqy/ 下，验证流程
  6. 提取公共代码到 packages/（HTTP client、日志）
  7. 跑通 CI

第 3-4 周：全员迁入
  8. 每人把自己的项目迁到 projects/{自己名字}/ 下
  9. 遇到重复代码 → 提 PR 到 packages/
  10. 补充 docs/

持续：
  11. 每周同步会，持续沉淀公共能力
  12. 定期清理 deprecated 项目
```

---

## 十五、Python 环境与包导入

### 15.1 让 packages/ 可被所有项目 import

在仓库根目录的 `pyproject.toml` 中把 packages 注册为可编辑安装的本地包：

```toml
# pyproject.toml
[project]
name = "scraper-hub"
version = "0.1.0"
requires-python = ">=3.10"

[tool.setuptools.packages.find]
include = ["packages*"]
```

每个人 clone 仓库后执行一次：

```bash
pip install -e .
```

之后所有项目都能 `from packages.http.client import HttpClient`。

### 15.2 环境隔离（3 种方案选 1 个）

| 方案 | 适合场景 | 操作 |
|------|---------|------|
| **全局 venv（推荐起步）** | 各项目依赖差异不大 | 仓库根目录一个 `.venv`，`pip install -e . && pip install -r requirements-base.txt` |
| **per-project venv** | 个别项目有特殊依赖冲突 | 在 `projects/{成员名}/{项目名}/` 下建 `.venv`，gitignore 已覆盖 |
| **Docker per-project** | 生产部署 / 依赖严重冲突 | 每个项目一个 `Dockerfile`（见第十六节） |

---

## 十六、协作规则

### 16.1 目标站点冲突处理

两个人想爬同一个站怎么办？

```
规则：
  1. 先到先得 — 项目清单里已有的站点，归属于已登记的人
  2. 不同维度可以并存 — 成员 A 爬「某站视频」，成员 B 爬「某站商品」，不冲突
  3. 有争议找 Lead 裁定
  4. 鼓励合并 — 如果功能高度重叠，合并成一个项目放到其中一人目录下
```

### 16.2 PR 模板

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->

## 改了什么
<!-- 简要描述本次改动 -->

## 影响范围
- [ ] 仅自己的项目 (`projects/{我的目录}/`)
- [ ] 公共库 (`packages/`)
- [ ] CI / 配置 / 脚本

## 测试情况
- [ ] 本地跑过，能正常抓取
- [ ] 数据格式无变化 / 已同步更新下游

## 有无 Breaking Change
- [ ] 无
- [ ] 有（请描述）：
```

### 16.3 pre-commit 钩子

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=500']
      - id: detect-private-key
```

新人 clone 后执行：

```bash
pip install pre-commit
pre-commit install
```

之后每次 `git commit` 自动检查代码格式、大文件、密钥泄漏。

### 16.4 Commit 规范

```
格式：{类型}({范围}): {描述}

类型：
  feat     新功能
  fix      修复
  refactor 重构
  docs     文档
  chore    杂项（CI、依赖更新）

范围 = 成员名/项目名 或 packages/模块名

示例：
  feat(yunqy/github-trending): 新增语言过滤
  fix(packages/http): 修复代理池连接泄漏
  docs: 更新反反爬经验库
```

---

## 十七、Docker 部署方案

### 17.1 通用 Dockerfile（放在仓库根目录）

```dockerfile
# Dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements-base.txt .
RUN pip install --no-cache-dir -r requirements-base.txt

COPY packages/ packages/
COPY pyproject.toml .
RUN pip install --no-cache-dir -e .

ARG OWNER
ARG PROJECT
COPY projects/${OWNER}/${PROJECT}/ projects/${OWNER}/${PROJECT}/
RUN if [ -f projects/${OWNER}/${PROJECT}/requirements.txt ]; then \
      pip install --no-cache-dir -r projects/${OWNER}/${PROJECT}/requirements.txt; \
    fi

ENV SCRAPER_OWNER=${OWNER}
ENV SCRAPER_PROJECT=${PROJECT}

CMD ["python", "-m", "projects.${OWNER}.${PROJECT}.scraper"]
```

### 17.2 构建与运行

```bash
# 构建 yunqy 的 github-trending 爬虫
docker build \
  --build-arg OWNER=yunqy \
  --build-arg PROJECT=github-trending \
  -t scraper-hub/yunqy-github-trending .

# 运行
docker run --env-file .env scraper-hub/yunqy-github-trending
```

### 17.3 docker-compose 批量编排（可选）

```yaml
# docker-compose.yml
services:
  yunqy-github-trending:
    build:
      context: .
      args:
        OWNER: yunqy
        PROJECT: github-trending
    env_file: .env
    restart: unless-stopped

  yunqy-github-repos:
    build:
      context: .
      args:
        OWNER: yunqy
        PROJECT: github-repos
    env_file: .env
    restart: unless-stopped

  # ... 按需添加更多
```

---

## 十八、监控与告警

### 18.1 每个爬虫运行后上报状态

```python
# packages/notify/heartbeat.py 提供的能力

上报内容：
  - 项目名（yunqy/github-trending）
  - 本次运行状态：success / partial / failed
  - 抓取条数
  - 耗时
  - 错误信息（如果有）
```

### 18.2 健康检查脚本

```
scripts/check_health.py 每天跑一次，检查：

  1. 哪些 running 状态的项目超过 24 小时没有上报？→ 告警
  2. 哪些项目连续 3 次 failed？→ 告警
  3. 哪些项目抓取量突然下降 50%+？→ 可能被反爬
  4. 汇总报告发群
```

---

## 十九、合规与风控

### 19.1 爬虫红线（必须遵守）

```
铁律：
  1. 遵守 robots.txt — 目标站明确禁止的路径不爬
  2. 控制频率 — 每个目标站在 config.yaml 中配好 rate_limit，默认 ≤ 2 req/s
  3. 不爬个人隐私数据 — 手机号、身份证、精确地理位置等绝对不采
  4. 不绕过付费墙 — 付费内容不爬
  5. 不做 DDoS — 禁止并发轰炸
  6. 数据仅内部使用 — 不公开传播、不倒卖
```

### 19.2 每个项目必须声明

在 `config.yaml` 中强制包含：

```yaml
compliance:
  robots_txt_checked: true     # 是否检查过 robots.txt
  rate_limit: 2.0              # 请求频率上限
  data_usage: "internal"       # internal / research / commercial
  personal_data: false         # 是否涉及个人数据
  notes: "仅采集公开页面数据"    # 备注
```

### 19.3 packages/http/client.py 内置限速

公共 HTTP 客户端默认强制限速，不允许绕过：

```
- 全局默认 1 req/s
- 可在 config.yaml 中调高，但上限 10 req/s
- 超过 10 req/s 需要 Lead 审批（在 config 中加 rate_limit_approved_by 字段）
```

---

## 二十、数据生命周期

### 20.1 数据不入 Git

所有抓取产出（JSON/CSV/DB）通过 `.gitignore` 排除，存在本地或云存储。

### 20.2 存储分层

```
热数据（最近 7 天）   →  本地磁盘 / Redis
温数据（7-90 天）     →  数据库（SQLite / MySQL）
冷数据（90 天+）      →  OSS/S3 归档 或 删除
```

### 20.3 清理策略

```yaml
# configs/data_retention.yaml

default:
  hot_days: 7
  warm_days: 90
  archive: true           # 超过 warm_days 自动归档到 OSS

overrides:
  yunqy/github-trending:
    warm_days: 365         # 趋势数据保留一年
  yunqy/github-repos:
    warm_days: 30          # 仓库数据 30 天后可归档
    archive: false         # 直接删除
```

---

## 二十一、新人 Onboarding 文档

以下是 `docs/onboarding.md` 应包含的内容：

```markdown
# 新人上手指南

## 1. 环境准备（10 分钟）

- Python >= 3.10
- Git
- 申请 GitHub Organization 权限（找 Lead）

## 2. Clone & 安装（5 分钟）

git clone git@github.com:your-org/scraper-hub.git
cd scraper-hub
python -m venv .venv
source .venv/bin/activate
make install

## 3. 创建你的第一个项目（5 分钟）

make new-project owner=你的名字 name=你的项目名

## 4. 编写爬虫

编辑 projects/你的名字/你的项目名/scraper.py
继承 BaseScraper，实现 fetch/parse/save 三个方法
参考 projects/yunqy/github-trending/ 的写法

## 5. 本地测试

make test-project owner=你的名字 name=你的项目名

## 6. 提交代码

git checkout -b feature/你的名字/你的项目名-init
git add projects/你的名字/你的项目名/
git commit -m "feat(你的名字/你的项目名): 初始化项目"
git push -u origin HEAD
# 去 GitHub 提 PR

## 7. 必读文档

- docs/coding_standards.md   编码规范
- docs/anti_detect_guide.md  反反爬经验
- packages/ 下各模块的 README   公共库用法

## 8. 日常注意

- 只改自己 projects/你的名字/ 下的代码
- 改公共库 packages/ 要提 PR 找 Lead 审批
- config.yaml 中必须填好 rate_limit 和 compliance
- 敏感信息（token/cookie/密码）绝不提交到 Git
```

---

## 二十二、对比：按人分目录 vs 按项目平铺

| 维度 | 按人分（推荐） | 按项目平铺 |
|------|-------------|-----------|
| 新增项目 | 直接建目录，零配置 | 要改 CODEOWNERS |
| 权限管理 | 每人一行通配符，按需增减 | 每个项目一行，持续膨胀 |
| 目录可读性 | 一眼看出谁负责什么 | 几十个目录混在一起 |
| 项目归属 | 路径里就有成员名 | 要查 CODEOWNERS 才知道 |
| 成员离职 | 保留代码，收回权限（CODEOWNERS 注释、GitHub 移除 Collaborator），可选交接给他人 | 到处找散落的项目 |
| 新人加入 | make add-member 自动完成 | 要逐个项目配权限 |
| 30+ 项目时 | 每人目录下若干项目，清晰 | 根目录 30+ 项目，混乱 |
