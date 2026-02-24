---
name: review-pr
description: Run Codex code review on a pull request and post results as a PR comment
user_invocable: true
---

# Codex PR Review

Run an automated code review on a pull request using OpenAI Codex CLI and post the results as a PR comment.

## Usage

- `/review-pr` — Review the PR associated with the current branch
- `/review-pr 42` — Review PR #42
- `/review-pr https://github.com/owner/repo/pull/42` — Review PR by URL

## Instructions

1. Parse `$ARGUMENTS` to extract the PR number:
   - If `$ARGUMENTS` is empty, the script will auto-detect from the current branch.
   - If `$ARGUMENTS` contains a number (e.g. `42` or `#42`), use that as the PR number.
   - If `$ARGUMENTS` contains a GitHub PR URL, extract the number from the URL path.

2. Run the review script:
   ```bash
   ~/.claude/skills/review-pr/scripts/codex-review-pr.sh <pr_number>
   ```
   If no PR number was resolved, run without arguments to let the script auto-detect.

3. Report the result to the user:
   - On success: Tell the user the review has been posted as a comment on the PR.
   - On failure: Show the error message from the script.
