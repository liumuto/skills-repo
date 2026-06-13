#!/usr/bin/env bash
# sync-skills.sh —— 把 skills 真相源 .agents/skills/ 镜像到 .claude/skills 与 .cursor/skills。
#
# 单一真相源：只改 .agents/skills/<name>/，然后运行本脚本。
# .claude/skills、.cursor/skills 是生成物，会被本脚本整体重建，请勿手改。
# 注意：本脚本不碰 .cursor/rules/（Cursor 规则是独立体系，手动维护）。
#
# 用法：在项目根目录执行   bash .agents/sync-skills.sh
set -euo pipefail

# 定位项目根（脚本位于 <root>/.agents/sync-skills.sh）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$ROOT/.agents/skills"

if [ ! -d "$SRC" ]; then
  echo "✗ 找不到真相源目录：$SRC" >&2
  echo "  请在项目根运行，且确保 .agents/skills/ 存在。" >&2
  exit 1
fi

TARGETS=("$ROOT/.claude/skills" "$ROOT/.cursor/skills")

copy_tree() {
  # $1 src dir, $2 dest dir —— 优先 rsync，回退到 cp
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$1/" "$2/"
  else
    rm -rf "$2"
    mkdir -p "$2"
    cp -R "$1/." "$2/"
  fi
}

for DEST in "${TARGETS[@]}"; do
  mkdir -p "$DEST"
  copy_tree "$SRC" "$DEST"
  echo "✓ 已同步 → ${DEST#$ROOT/}"
done

echo "完成：.agents/skills → .claude/skills, .cursor/skills"
