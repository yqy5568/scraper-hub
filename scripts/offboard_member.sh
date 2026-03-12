#!/bin/bash
set -e

MEMBER_NAME=$1

if [ -z "$MEMBER_NAME" ]; then
    echo "用法: $0 <成员名>"
    echo "示例: $0 zhangsan"
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MEMBER_DIR="$REPO_ROOT/projects/$MEMBER_NAME"
CODEOWNERS="$REPO_ROOT/.github/CODEOWNERS"

if [ ! -d "$MEMBER_DIR" ]; then
    echo "错误: $MEMBER_DIR 不存在"
    exit 1
fi

if [ "$MEMBER_NAME" = "yunqy" ]; then
    echo "错误: 不能 offboard Lead 自己"
    exit 1
fi

# 1. CODEOWNERS 中注释掉该成员（不删除，保留记录）
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|^projects/$MEMBER_NAME/|# [已离职] projects/$MEMBER_NAME/|" "$CODEOWNERS"
else
    sed -i "s|^projects/$MEMBER_NAME/|# [已离职] projects/$MEMBER_NAME/|" "$CODEOWNERS"
fi
echo "✅ CODEOWNERS 已注释: projects/$MEMBER_NAME/"

# 2. 将该成员所有项目 README 标记为 archived
for readme in "$MEMBER_DIR"/*/README.md; do
    if [ -f "$readme" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/^status: running/status: archived/' "$readme"
            sed -i '' 's/^status: paused/status: archived/' "$readme"
            sed -i '' 's/^status: pending/status: archived/' "$readme"
        else
            sed -i 's/^status: running/status: archived/' "$readme"
            sed -i 's/^status: paused/status: archived/' "$readme"
            sed -i 's/^status: pending/status: archived/' "$readme"
        fi
    fi
done
echo "✅ 所有项目状态已标记为 archived"

# 3. 移除 GitHub Collaborator 权限（从注释前的 CODEOWNERS 备份获取，或从注释行解析）
GITHUB_ID=$(grep "projects/$MEMBER_NAME/" "$CODEOWNERS" | grep -oE '@[a-zA-Z0-9_-]+' | grep -v yqy5568 | head -1 | tr -d '@')
if command -v gh &>/dev/null && [ -n "$GITHUB_ID" ] && [ "$GITHUB_ID" != "yqy5568" ]; then
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
    if [ -n "$REPO" ]; then
        gh api repos/$REPO/collaborators/$GITHUB_ID -X DELETE 2>/dev/null && \
            echo "✅ 已移除 @$GITHUB_ID 的仓库权限" || \
            echo "⚠️  移除权限失败，请手动操作"
    fi
else
    echo "⚠️  请手动移除该成员的 GitHub 仓库权限"
fi

echo ""
echo "离职处理完成！"
echo "  - 代码和分支已保留（不删除）"
echo "  - 权限已收回"
echo "  - 如需交接项目给其他人，编辑 CODEOWNERS 把该行的 @成员ID 换成接手人的 ID"
