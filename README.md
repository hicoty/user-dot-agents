# user-dot-agents

> 集中版控 **Claude Code 使用者層級設定**(skills / hooks / settings.json / CLAUDE.md),以 symlink 連回家目錄。換機或重灌時,`git clone` + 執行安裝腳本即可一鍵還原。

<p align="left">
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-user%20config-6E56CF?logo=anthropic&logoColor=white">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-4C9A2A">
  <img alt="Shell" src="https://img.shields.io/badge/shell-Bash-121011?logo=gnubash&logoColor=white">
  <img alt="Windows" src="https://img.shields.io/badge/Windows-PowerShell-5391FE?logo=powershell&logoColor=white">
  <img alt="Install" src="https://img.shields.io/badge/install-symlink-1f6feb">
  <img alt="Idempotent" src="https://img.shields.io/badge/install-idempotent-success">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-yellow">
</p>

---

## 為什麼需要這個 Repo

Claude Code 的使用者設定散落在家目錄(`~/.claude/`、`~/.agents/`),難以版控、難以在多台機器間同步,重灌後更要從頭設定一次。

這個 Repo 把這些設定**集中成單一可版控的來源(single source of truth)**,再用 symlink 連回原本的家目錄位置 —— 設定照常被 Claude Code 讀取,而你只需要維護這一份 Git 倉庫:

- 🔄 **多機同步**:任何一台改完 `git push`,其他機器 `git pull` 即生效(symlink 直連,免再次安裝)。
- ⚡ **一鍵還原**:新機器或重灌只要 `git clone` + 執行安裝腳本(`install.sh` / `install.ps1`)。
- 🧬 **可追溯**:設定變更全程走 Git history,可 review、可回溯、可分支實驗。

## ✨ 特色

| | |
| --- | --- |
| 🗂 **集中管理** | skills / hooks / `settings.json` / `CLAUDE.md` 全部納入單一 Repo |
| 🔗 **Symlink 連回** | 不複製檔案,連結直連;改 Repo 即時反映到 Claude Code |
| ♻️ **可重複執行** | 安裝腳本為 idempotent,重跑只會覆蓋更新連結、不報錯 |
| 🛟 **不毀資料** | 目標若為既有實體檔案,會先備份為 `*.backup-<timestamp>` 再建立連結 |
| 🌐 **跨平台** | macOS / Linux 原生支援;Windows 可用原生 PowerShell 或 Git Bash / WSL |
| 🛡️ **安全防護** | 內建 hook 攔截危險 Bash 指令的變形寫法(絕對路徑、管線包裹等) |

## 📦 內容物

### Skills(`skills/`)

| Skill | 用途 |
| --- | --- |
| [`baoyu-infographic`](skills/baoyu-infographic/) | 生成專業資訊圖表 —— 21 種版型 × 22 種視覺風格,自動推薦組合並產出可發佈成品 |
| [`frontend-design`](skills/frontend-design/) | 產出有設計感、production-grade 的前端介面,避開常見的 AI 樣板感 |
| [`illustrated-slides-with-nano-banana`](skills/illustrated-slides-with-nano-banana/) | 以 AI 生成「整頁即一張圖」的插畫式簡報(PPTX / PDF),文字直接嵌入畫面 |
| [`find-skills`](skills/find-skills/) | 協助探索並安裝可用的 agent skills,擴充 Claude Code 能力 |

### Hooks(`hooks/`)

| Hook | 用途 |
| --- | --- |
| [`guard-dangerous-commands.py`](hooks/guard-dangerous-commands.py) | `PreToolUse` 攔截器。`permissions.deny` 只做前綴比對,擋不住 `/bin/rm`、`bash -c` 包裹、管線、`find -delete` 等變形;此 hook 解析整段指令,命中即 deny |

### 設定檔

| 檔案 | 說明 |
| --- | --- |
| [`settings.json`](settings.json) | 全域 Claude Code 設定:權限黑名單、hook 註冊、statusline、已啟用 plugins / marketplaces 等 |
| [`CLAUDE.md`](CLAUDE.md) | 全域使用者指令 —— 減少常見 LLM 編碼失誤的行為準則 |

## 🚀 快速開始

### macOS / Linux

```bash
git clone https://github.com/deancourse/user-dot-agents.git
cd user-dot-agents
bash install.sh
```

### Windows

兩種方式擇一:

**(A) 原生 PowerShell(建議)**

```powershell
git clone https://github.com/deancourse/user-dot-agents.git
cd user-dot-agents
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**(B) Git Bash / WSL**

```bash
bash install.sh
```

> [!IMPORTANT]
> - **建立 symlink 需要權限**:Windows 建立 symlink 需「開發人員模式」或「系統管理員」。
>   - `install.ps1` 會**自動偵測**:若兩者皆無,預設**跳出 UAC 視窗**以系統管理員身分重跑(免改系統設定)。
>   - 不想提權的話,加 `-NoElevate` 參數(`powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoElevate`),腳本改為**直接開啟「開發人員模式」設定頁**引導你打開開關,打開後再重跑即可。
>   - 一勞永逸建議:設定 → 隱私權與安全性 → 開發人員選項 → 開啟「開發人員模式」,之後一般視窗就能建 symlink。
>   - `install.sh` 走 Git Bash / WSL,已自動設定 `MSYS=winsymlinks:nativestrict` 以建立原生 symlink。
> - **PowerShell 執行原則**:若被擋下,可加 `-ExecutionPolicy Bypass`(如上),或先 `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`。
> - **WSL**:原生支援 symlink,直接執行即可。
> - 若不想用 symlink,也可改用 `git clone` 後手動複製檔案到對應位置(但之後就無法靠 `git pull` 自動同步)。

## 🔗 連結對應表

執行安裝腳本後會建立以下 symlink(箭頭右側為連回的家目錄位置):

| Repo 內來源 | 連結到 |
| --- | --- |
| `skills/`(整個資料夾) | `~/.agents/skills` **且** `~/.claude/skills` |
| `hooks/` | `~/.claude/hooks` |
| `settings.json` | `~/.claude/settings.json` |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` |

> [!NOTE]
> skills 以**整個資料夾**連到 `.agents` 與 `.claude` 兩個位置,維持 Claude Code 原本的查找結構;之後在 repo 內新增 skill 子資料夾會自動生效,免重跑安裝腳本。

## ⚙️ 安裝腳本行為

`install.sh` 與 `install.ps1` 行為一致:

| 特性 | 說明 |
| --- | --- |
| **可重複執行(idempotent)** | 既有的 symlink 直接覆蓋更新,重跑不會出錯 |
| **不會刪資料** | 目標若已存在**實體**檔案/資料夾,先備份為 `<原路徑>.backup-<時間戳>` 再建立 symlink |
| **失效連結自動修復** | 既有的失效(dangling)symlink 會被移除後重建 |
| **路徑無關** | 可從任意工作目錄呼叫(腳本自動以自身所在目錄為 Repo 根) |

## 📝 注意事項

- **`settings.local.json` 未納入版控**:該檔通常含機器/個人專屬的權限與環境設定,刻意保留在本機 `~/.claude/`,不放進此 Repo(已列入 `.gitignore`)。
- `settings.json` 內以 `$HOME/.claude/...` 參照 hooks 與 statusline;安裝後路徑會透過 symlink 正確解析。
- 安裝腳本產生的 `*.backup-*` 備份檔已列入 `.gitignore`,不會被誤入版控。

## 🗂 目錄結構

```
user-dot-agents/
├── skills/                          # 各 skill 實體資料夾(連回 ~/.agents/skills 與 ~/.claude/skills)
│   ├── baoyu-infographic/
│   ├── find-skills/
│   ├── frontend-design/
│   └── illustrated-slides-with-nano-banana/
├── hooks/                           # 連回 ~/.claude/hooks
│   └── guard-dangerous-commands.py  #   攔截危險 Bash 指令的 PreToolUse hook
├── settings.json                    # 連回 ~/.claude/settings.json
├── CLAUDE.md                        # 連回 ~/.claude/CLAUDE.md(全域使用者指令)
├── install.sh                       # macOS / Linux / Git Bash / WSL 安裝腳本
├── install.ps1                      # Windows 原生 PowerShell 安裝腳本
└── README.md
```

## 📄 License

本 Repo 以 [MIT License](LICENSE) 釋出。

> 註:`skills/` 內各 skill 為第三方來源,其授權以各自資料夾內的 `LICENSE` / `SKILL.md` 聲明為準。
