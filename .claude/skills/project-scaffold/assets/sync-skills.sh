#!/usr/bin/env bash
# sync-skills.sh —— 把 .agents/ 下的 skills 与 rules 真相源镜像到 .claude/ 与 .cursor/。
#
# 单一真相源：
#   - skills：只改 .agents/skills/<name>/
#   - rules ：只改 .agents/rules/*.md
# 然后运行本脚本。
#
# 镜像规则：
#   .agents/skills → .claude/skills、.cursor/skills    （整体镜像）
#   .agents/rules  → .claude/rules                       （整体镜像，保持 .md 扩展名）
#   .agents/rules  → .cursor/rules                       （递归同步，.md → .mdc 扩展名）
#
# .claude/skills、.cursor/skills、.claude/rules、.cursor/rules 都是生成物，会被本脚本整体重建，请勿手改。
#
# 用法：在项目根目录执行   bash .agents/sync-skills.sh
set -euo pipefail

# 定位项目根（脚本位于 <root>/.agents/sync-skills.sh）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILLS_SRC="$ROOT/.agents/skills"
RULES_SRC="$ROOT/.agents/rules"

mirror_tree() {
  # $1 src dir, $2 dest dir —— 优先 rsync，回退到 cp
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$1/" "$2/"
  else
    rm -rf "$2"
    mkdir -p "$2"
    cp -R "$1/." "$2/"
  fi
}

mirror_rules_to_mdc() {
  # $1 src dir (.agents/rules), $2 dest dir (.cursor/rules)
  # 递归把 $1 下所有 .md 同结构生成 .mdc 到 $2，并清理孤儿 .mdc / 空子目录。
  mkdir -p "$2"
  find "$2" -type f -name '*.mdc' -delete 2>/dev/null || true
  (cd "$1" && find . -type f -name '*.md' -print0) | while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    dest_dir="$2/$(dirname "$rel")"
    base="$(basename "$rel" .md)"
    mkdir -p "$dest_dir"
    cp "$1/$rel" "$dest_dir/${base}.mdc"
  done
  find "$2" -mindepth 1 -type d -empty -delete 2>/dev/null || true
}

# ---- skills ----
if [ -d "$SKILLS_SRC" ]; then
  for DEST in "$ROOT/.claude/skills" "$ROOT/.cursor/skills"; do
    mkdir -p "$DEST"
    mirror_tree "$SKILLS_SRC" "$DEST"
    echo "✓ 已同步 skills → ${DEST#$ROOT/}"
  done
else
  echo "⚠ 跳过 skills：$SKILLS_SRC 不存在"
fi

# ---- rules ----
if [ -d "$RULES_SRC" ]; then
  mkdir -p "$ROOT/.claude/rules"
  mirror_tree "$RULES_SRC" "$ROOT/.claude/rules"
  echo "✓ 已同步 rules  → .claude/rules"

  mirror_rules_to_mdc "$RULES_SRC" "$ROOT/.cursor/rules"
  echo "✓ 已同步 rules  → .cursor/rules（.md → .mdc）"
else
  echo "⚠ 跳过 rules：$RULES_SRC 不存在"
fi

echo "完成"
