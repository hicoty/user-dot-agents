#!/usr/bin/env bash
#
# install.sh — 將本 repo 內容以 symlink 連回使用者家目錄。
#
# 對應關係:
#   skills/<name>/   ->  ~/.agents/skills/<name>   且   ~/.claude/skills/<name>
#   hooks/           ->  ~/.claude/hooks
#   settings.json    ->  ~/.claude/settings.json
#   CLAUDE.md        ->  ~/.claude/CLAUDE.md
#
# 跨平台:
#   - macOS / Linux:直接執行 `bash install.sh`
#   - Windows:於 Git Bash 或 WSL 執行 `bash install.sh`
#       Git Bash 需開啟「開發人員模式」或以系統管理員身分執行,才能建立原生 symlink。
#
# 特性:
#   - 可重複執行(idempotent):既有 symlink 直接覆蓋更新。
#   - 既有「實體」檔案/資料夾會先備份為 <path>.backup-<timestamp>,不會被刪除。

set -u

# ── 解析 repo 根目錄(本 script 所在目錄,可從任意路徑呼叫)─────────────
SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
REPO="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"

# ── 偵測作業系統;Windows(Git Bash/MSYS/Cygwin)啟用原生 symlink ──────────
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW* | MSYS* | CYGWIN*)
    export MSYS=winsymlinks:nativestrict
    export CYGWIN="${CYGWIN:-} winsymlinks:nativestrict"
    echo "ℹ️  偵測到 Windows(Git Bash/MSYS)。建立 symlink 需『開發人員模式』或系統管理員權限。"
    ;;
esac

CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$HOME/.agents"
STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo backup)"

# make_link <來源(repo 內絕對路徑)> <目標(家目錄路徑)>
make_link() {
  src="$1"
  dest="$2"

  if [ ! -e "$src" ]; then
    echo "  ⤬ 跳過(來源不存在):$src"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    # 既有 symlink(含失效的 dangling):直接移除後重建
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    # 既有實體檔案/資料夾:備份保留,不刪除
    mv "$dest" "${dest}.backup-${STAMP}"
    echo "  ⚑ 已備份既有檔案:${dest} -> ${dest}.backup-${STAMP}"
  fi

  ln -s "$src" "$dest"
  echo "  ✓ ${dest}  ->  ${src}"
}

echo "Repo : $REPO"
echo "家目錄: $HOME"
echo

echo "[1/4] settings.json"
make_link "$REPO/settings.json" "$CLAUDE_DIR/settings.json"

echo "[2/4] CLAUDE.md"
make_link "$REPO/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

echo "[3/4] hooks(整個資料夾)"
make_link "$REPO/hooks" "$CLAUDE_DIR/hooks"

echo "[4/4] skills(每個同時連到 .agents 與 .claude)"
mkdir -p "$AGENTS_DIR/skills" "$CLAUDE_DIR/skills"
found_skill=0
for skill_path in "$REPO"/skills/*/; do
  [ -d "$skill_path" ] || continue
  found_skill=1
  name="$(basename "$skill_path")"
  make_link "$REPO/skills/$name" "$AGENTS_DIR/skills/$name"
  make_link "$REPO/skills/$name" "$CLAUDE_DIR/skills/$name"
done
[ "$found_skill" -eq 0 ] && echo "  ⤬ skills/ 目錄內沒有任何 skill 子資料夾"

echo
echo "✅ 完成。可重複執行本腳本以同步更新連結。"
