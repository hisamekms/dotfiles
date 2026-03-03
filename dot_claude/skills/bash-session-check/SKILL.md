---
name: bash-session-check
description: bash実行の検証用。scriptをbashで実行し、CLAUDE_SESSION_IDを環境変数として渡す。`bash-session-check` または「bash実行検証」で起動。
---

# Bash Session Check

`$ARGUMENTS` は任意メッセージとしてscriptへ渡す。

```bash
CLAUDE_SESSION_ID="${CLAUDE_SESSION_ID}" \
<skills_root>/bash-session-check/scripts/check.sh "$ARGUMENTS"
```

scriptの標準出力をそのままユーザーに返す。
