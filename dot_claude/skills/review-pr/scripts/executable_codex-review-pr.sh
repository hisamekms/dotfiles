#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "codex-review-pr: $1" >&2
  exit 1
}

# --- Resolve PR number ---
pr_number="${1:-}"
if [[ -z "$pr_number" ]]; then
  pr_number="$(gh pr view --json number -q '.number' 2>/dev/null)" \
    || fail "No PR number provided and could not detect one from the current branch."
fi

# Strip leading # if present (e.g. "#42" -> "42")
pr_number="${pr_number#\#}"

# Validate it's a number
[[ "$pr_number" =~ ^[0-9]+$ ]] || fail "Invalid PR number: $pr_number"

echo "Reviewing PR #${pr_number} ..."

# --- Get diff ---
diff="$(gh pr diff "$pr_number")" \
  || fail "Failed to get diff for PR #${pr_number}."

[[ -n "$diff" ]] || fail "PR #${pr_number} has an empty diff."

# --- Run Codex review ---
review_prompt="You are a senior code reviewer. Review the following pull request diff.
Focus on:
- Bugs and logic errors
- Security vulnerabilities
- Performance issues
- Code style and readability concerns

For each issue found, specify the file and line context.
If the code looks good, say so briefly.
Keep the review concise and actionable."

review_result="$(echo "$diff" | codex --dangerously-bypass-approvals-and-sandbox exec "$review_prompt" 2>/dev/null)" \
  || fail "Codex review failed for PR #${pr_number}."

[[ -n "$review_result" ]] || fail "Codex returned an empty review for PR #${pr_number}."

# --- Post comment ---
comment_body="$(cat <<EOF
## Codex Review

$review_result

---
*Automated review by OpenAI Codex CLI*
EOF
)"

gh pr comment "$pr_number" --body "$comment_body" \
  || fail "Failed to post review comment on PR #${pr_number}."

echo "Review posted on PR #${pr_number}."
