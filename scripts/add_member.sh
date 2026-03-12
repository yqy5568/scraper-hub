#!/bin/bash
set -e

MEMBER_NAME=$1
GITHUB_ID=$2

if [ -z "$MEMBER_NAME" ] || [ -z "$GITHUB_ID" ]; then
    echo "用法: $0 <成员名> <GitHub用户名>"
    echo "示例: $0 zhangsan zhangsan-github"
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MEMBER_DIR="$REPO_ROOT/projects/$MEMBER_NAME"

if [ -d "$MEMBER_DIR" ]; then
    echo "错误: $MEMBER_DIR 已存在"
    exit 1
fi

# 1. 创建成员目录
mkdir -p "$MEMBER_DIR"
touch "$MEMBER_DIR/.gitkeep"
echo "✅ 创建目录: projects/$MEMBER_NAME/"

# 2. 追加 CODEOWNERS
CODEOWNERS="$REPO_ROOT/.github/CODEOWNERS"
ENTRY="projects/$MEMBER_NAME/**"

if grep -q "$ENTRY" "$CODEOWNERS" 2>/dev/null; then
    echo "⚠️  CODEOWNERS 中已存在 $ENTRY"
else
    # 在"成员目录"注释块后追加
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/^projects\/yunqy/a\\
projects/$MEMBER_NAME/**          @$GITHUB_ID          @yqy5568
" "$CODEOWNERS"
    else
        sed -i "/^projects\/yunqy/a projects/$MEMBER_NAME/**          @$GITHUB_ID          @yqy5568" "$CODEOWNERS"
    fi
    echo "✅ CODEOWNERS 已追加: projects/$MEMBER_NAME/** @$GITHUB_ID"
fi

# 3. 邀请 GitHub Collaborator
if command -v gh &>/dev/null; then
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
    if [ -n "$REPO" ]; then
        gh api repos/$REPO/collaborators/$GITHUB_ID -X PUT -f permission=push 2>/dev/null && \
            echo "✅ 已邀请 @$GITHUB_ID 为仓库 Collaborator" || \
            echo "⚠️  邀请 Collaborator 失败，请手动添加"
    fi
else
    echo "⚠️  gh CLI 未安装，请手动邀请 @$GITHUB_ID 为 Collaborator"
fi

echo ""
echo "入职完成！下一步请通知 $MEMBER_NAME:"
echo "  1. 接受 GitHub 仓库邀请"
echo "  2. git clone 仓库 && make install"
echo "  3. make new-project owner=$MEMBER_NAME name=项目名"
