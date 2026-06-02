#!/usr/bin/env python3
"""PreToolUse guard: 阻擋危險 Bash 指令的變形寫法。

permissions.deny 只做「前綴比對」，擋不住絕對路徑(/bin/rm)、bash -c 包裹、
管線、find -delete 等變形。此 hook 解析整個 command 字串，命中即 deny。

輸出 JSON deny 決策給 Claude Code；不命中則靜默 exit 0（交回正常權限流程）。
誤擋時可在終端機用前綴 `! ` 自行執行。
"""
import json
import re
import sys

# 命令位置前綴：行首，或被 ; & | ( ) ` $ 等分隔符隔開（避開純參數誤判可在規則層處理）
PRE = r"(?:^|[\s;&|()`{])"
# 可選的絕對/相對路徑前綴，例如 /bin/rm、/usr/sbin/diskutil
PATH = r"(?:[/\w.-]+/)?"

RULES = [
    ("rm 遞迴/強制刪除",
     rf"{PRE}{PATH}rm\b[^\n;&|]*?(?:-{{1,2}}[\w-]*[rRf]|--recursive|--force|--no-preserve-root)"),
    ("sudo 提權",
     rf"{PRE}sudo\b"),
    ("dd 磁碟寫入",
     rf"{PRE}{PATH}dd\b(?=[^\n;&|]*\b(?:if|of|bs|count|seek)=)"),
    ("dd 指令",
     rf"{PRE}{PATH}dd\s"),
    ("mkfs 格式化",
     rf"{PRE}{PATH}mkfs(?:\.\w+)?\b"),
    ("diskutil erase 抹除磁碟",
     rf"{PRE}{PATH}diskutil\s+erase\w*"),
    ("chmod 777 權限濫用",
     rf"{PRE}{PATH}chmod\s+(?:-R\s+)?0?777\b"),
    ("git reset --hard 不可逆重置",
     r"\bgit\s+reset\s+--hard\b"),
    ("git push 強制推送",
     r"\bgit\s+push\b[^\n;&|]*?(?:--force(?:-with-lease)?\b|\s-f\b)"),
    ("git clean -f 強制清除",
     r"\bgit\s+clean\b[^\n;&|]*?-\w*f"),
    ("git branch -D 強制刪除分支",
     r"\bgit\s+branch\b[^\n;&|]*?-\w*D"),
    ("shutdown 關機",
     rf"{PRE}{PATH}shutdown\b"),
    ("reboot/halt/poweroff 重開或關機",
     rf"{PRE}{PATH}(?:reboot|halt|poweroff)\b"),
    ("truncate 截斷檔案",
     rf"{PRE}{PATH}truncate\b"),
    (": > 清空檔案",
     r":\s*>\s*\S"),
    ("find -delete 批次刪除",
     r"\bfind\b[^\n]*\s-delete\b"),
]

COMPILED = [(name, re.compile(pat, re.IGNORECASE)) for name, pat in RULES]


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # 解析失敗不阻擋，避免誤殺

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    cmd = (data.get("tool_input") or {}).get("command", "")
    if not cmd:
        sys.exit(0)

    # 規範化：換行/tab 轉空白，方便單行掃描
    norm = re.sub(r"[\t\n\r]+", " ", cmd)

    for name, rx in COMPILED:
        if rx.search(norm):
            reason = (
                f"已被本機安全規則攔截：{name}。\n"
                f"此類指令（含絕對路徑、bash -c、管線等變形）禁止由 Claude 執行。\n"
                f"若你確認要執行，請在終端機輸入框用前綴「! 」自行手動執行。"
            )
            out = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
            print(json.dumps(out, ensure_ascii=False))
            sys.exit(0)

    sys.exit(0)


if __name__ == "__main__":
    main()
