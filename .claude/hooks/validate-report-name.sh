#!/bin/bash
# Validates audit report filenames match {YYYY-MM-DD}-audit-{domain}.md
# Input: JSON on stdin with tool_input.file_path
# Exit 2 to block, exit 0 to allow

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" == */docs/w-audit/*.md ]]; then
  BASENAME=$(basename "$FILE_PATH")
  if [[ ! "$BASENAME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-audit-.+\.md$ ]]; then
    echo "Blocked: Report filename must match {YYYY-MM-DD}-audit-{domain}.md. Got: $BASENAME" >&2
    exit 2
  fi
fi

exit 0
