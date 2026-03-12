# 新人上手指南

## 1. 环境准备

- Python >= 3.10
- Git
- 申请 GitHub Organization 权限（找 Lead）

## 2. Clone & 安装

```bash
git clone git@github.com:your-org/scraper-hub.git
cd scraper-hub

python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

make install
```

## 3. 创建你的第一个项目

```bash
make new-project owner=你的名字 name=你的项目名
```

这会在 `projects/你的名字/你的项目名/` 下生成模板文件。

## 4. 编写爬虫

编辑 `projects/你的名字/你的项目名/scraper.py`，继承 `BaseScraper`，实现三个方法：

```python
from packages.core.base_scraper import BaseScraper

class Scraper(BaseScraper):
    def __init__(self):
        super().__init__("你的名字/你的项目名")

    def fetch(self, url):
        return self.client.get(url).json()

    def parse(self, raw_data):
        # 返回解析后的数据列表
        return raw_data.get("items", [])

    def save(self, items):
        from packages.storage import FileStore
        store = FileStore("data/你的名字/你的项目名")
        store.save_jsonl(items, "result.jsonl")
```

参考 `projects/yunqy/github-trending/` 的完整写法。

## 5. 配置

编辑 `config.yaml`，填写目标站点、频率限制、合规声明等信息。

## 6. 本地测试

```bash
# 运行
make run owner=你的名字 name=你的项目名

# 测试
make test-project owner=你的名字 name=你的项目名
```

## 7. 提交代码

```bash
git checkout -b feature/你的名字/你的项目名-init
git add projects/你的名字/你的项目名/
git commit -m "feat(你的名字/你的项目名): 初始化项目"
git push -u origin HEAD
```

然后去 GitHub 提 PR。

## 8. 必读文档

- [编码规范](coding_standards.md)
- [反反爬经验库](anti_detect_guide.md)

## 9. 日常注意

- 只改自己 `projects/你的名字/` 下的代码
- 改公共库 `packages/` 要提 PR 找 Lead 审批
- `config.yaml` 中必须填好 `rate_limit` 和 `compliance`
- 敏感信息（token/cookie/密码）绝不提交到 Git
- 每次 commit 遵循规范：`feat(你的名字/项目名): 描述`

## 离职交接流程

### Lead 操作

```bash
# 1. 运行离职脚本（收回权限，保留代码）
make offboard-member name=离职成员名

# 2. 提交变更
git add -A
git commit -m "chore: offboard 成员名"
git push
```

### 交接给其他人（可选）

如果需要其他成员接手离职成员的项目：

```bash
# 方式 1（推荐）：项目留在原目录，只改 CODEOWNERS 中的负责人
# 编辑 .github/CODEOWNERS，把 @离职成员ID 改成 @接手人ID

# 方式 2：把项目移到接手人目录
git mv projects/离职成员/项目名 projects/接手人/项目名
```
