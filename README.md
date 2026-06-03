# user-dot-agents

集中版控 Claude Code 的**使用者層級設定**(skills / hooks / settings.json / CLAUDE.md),再以 symlink 連回家目錄使用。
換新機器或重灌時,只要 `git clone` + 執行 `install.sh` 即可一鍵還原。

## 目錄結構

```
user-dot-agents/
├── skills/                          # 各 skill 的實體資料夾(原本在 ~/.agents/skills/)
│   ├── baoyu-infographic/
│   ├── find-skills/
│   ├── frontend-design/
│   └── illustrated-slides-with-nano-banana/
├── hooks/                           # 原本在 ~/.claude/hooks/
│   └── guard-dangerous-commands.py  #   攔截危險 Bash 指令的 PreToolUse hook
├── settings.json                    # 原本在 ~/.claude/settings.json
├── CLAUDE.md                        # 全域使用者指令

├── install.sh                       # macOS / Linux / Git Bash / WSL 安裝腳本
├── install.ps1                      # Windows 原生 PowerShell 安裝腳本
└── README.md
```

## 連結對應表

執行 `install.sh` 後會建立以下 symlink(箭頭右側為連回的家目錄位置):

| repo 內來源 | 連結到 |
| --- | --- |
| `skills/<name>/` | `~/.agents/skills/<name>` **且** `~/.claude/skills/<name>` |
| `hooks/` | `~/.claude/hooks` |
| `settings.json` | `~/.claude/settings.json` |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` |

> skills 會**同時**連到 `.agents` 與 `.claude` 兩個位置,維持原本的查找結構。

## 使用方式

### macOS / Linux

```bash
git clone <repo-url> user-dot-agents
cd user-dot-agents
bash install.sh
```

### Windows

兩種方式擇一:

**(A) 原生 PowerShell(建議)**

```powershell
git clone <repo-url> user-dot-agents
cd user-dot-agents
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**(B) Git Bash / WSL**

```bash
bash install.sh
```

注意事項:
- **建立 symlink 需要權限**:Windows 建立 symlink 需「開發人員模式」或「系統管理員」。
  - `install.ps1` 會**自動偵測**:若兩者皆無,預設**跳出 UAC 視窗**以系統管理員身分重跑(免改系統設定)。
  - 不想提權的話,加 `-NoElevate` 參數(`powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoElevate`),腳本改為**直接開啟「開發人員模式」設定頁**引導你打開開關,打開後再重跑即可。
  - 一勞永逸建議:設定 → 隱私權與安全性 → 開發人員選項 → 開啟「開發人員模式」,之後一般視窗就能建 symlink。
  - `install.sh` 走 Git Bash/WSL,已自動設定 `MSYS=winsymlinks:nativestrict` 以建立原生 symlink。
- **PowerShell 執行原則**:若被擋下,可加 `-ExecutionPolicy Bypass`(如上),或先 `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`。
- **WSL**:原生支援 symlink,直接執行即可。
- 若不想用 symlink,也可改用 `git clone` 後手動複製檔案到對應位置(但之後就無法靠 `git pull` 自動同步)。

## 行為說明

`install.sh` 的特性:

- **可重複執行(idempotent)**:既有的 symlink 會直接覆蓋更新,重跑不會出錯。
- **不會刪資料**:若目標位置已存在**實體**檔案/資料夾,會先備份為 `<原路徑>.backup-<時間戳>`,再建立 symlink。
- **失效連結自動修復**:既有的失效(dangling)symlink 會被移除後重建。
- **路徑無關**:可從任意工作目錄呼叫(腳本自動以自身所在目錄為 repo 根)。

## 注意事項

- **`settings.local.json` 未納入版控**:該檔通常包含機器/個人專屬的權限與環境設定,刻意保留在本機 `~/.claude/`,不放進此 repo。
- `settings.json` 內以 `$HOME/.claude/...` 參照 hooks 與 statusline,安裝後路徑會透過 symlink 正確解析。
