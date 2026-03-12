# scraper-hub

爬虫团队 Monorepo —— 弹性团队，每人多个独立项目，共享公共基础设施。

## 目录结构

```
scraper-hub/
├── packages/          公共库（HTTP 客户端、代理池、反反爬、存储、通知、工具）
├── projects/          按成员分目录，每人管理自己的所有爬虫项目
│   ├── yunqy/       Lead 目录
│   ├── _template/     新项目模板
│   └── ...            （新成员由 make add-member 自动创建）
├── scripts/           运维脚本
├── configs/           全局配置
└── docs/              团队文档
```

## 快速开始

```bash
# 1. Clone
git clone git@github.com:your-org/scraper-hub.git
cd scraper-hub

# 2. 安装
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
make install

# 3. 创建新项目
make new-project owner=你的名字 name=项目名

# 4. 运行
make run owner=你的名字 name=项目名

# 5. 测试
make test-project owner=你的名字 name=项目名
```

## 权限规则

- **自己的目录** (`projects/你的名字/`) —— 全权管理，随时加新项目
- **别人的目录** —— 只读，修改需提 PR 由对方审批
- **公共库** (`packages/`) —— 修改需提 PR 由 Lead 审批
- **基础设施** (`.github/`, `scripts/`, `configs/`) —— 仅 Lead 可修改

## 常用命令

| 命令 | 说明 |
|------|------|
| `make install` | 安装全局依赖 |
| `make new-project owner=xxx name=yyy` | 创建新项目 |
| `make add-member name=xxx github=yyy` | 新成员入职 |
| `make offboard-member name=xxx` | 成员离职（保留代码，收回权限） |
| `make run owner=xxx name=yyy` | 运行指定项目 |
| `make test` | 全量测试 |
| `make test-owner owner=xxx` | 测试某人所有项目 |
| `make test-project owner=xxx name=yyy` | 测试指定项目 |
| `make test-smoke` | 冒烟测试（真实请求） |
| `make lint` | 代码检查 |
| `make registry` | 生成项目清单 |

## 文档

- [新人上手指南](docs/onboarding.md)
- [编码规范](docs/coding_standards.md)
- [反反爬经验库](docs/anti_detect_guide.md)
- [设计方案](MONOREPO_DESIGN.md)
