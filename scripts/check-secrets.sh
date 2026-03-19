#!/bin/bash
# Pre-push hook: uses claude -p to check for sensitive information
# that should not be pushed to the public repository.

DIFF=$(git diff --cached --diff-filter=d HEAD @{push} -- . 2>/dev/null || git diff HEAD~1 --diff-filter=d -- .)

if [ -z "$DIFF" ]; then
  exit 0
fi

RESULT=$(echo "$DIFF" | claude -p "You are a security reviewer for a public dotfiles repository.
Check the following git diff for any sensitive information that should NOT be committed to a public repo:
- API keys, tokens, secrets, passwords
- Private IP addresses, internal hostnames
- Personal information (real names, emails, phone numbers, addresses)
- Private file paths that reveal sensitive directory structures

If you find any issues, output 'BLOCKED: ' followed by a description of each issue found.
If everything looks safe, output only 'OK'.
Be strict - when in doubt, flag it.")

echo "$RESULT"

if echo "$RESULT" | grep -q "^BLOCKED:"; then
  exit 1
fi
