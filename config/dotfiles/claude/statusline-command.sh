#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
context_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

cd "$cwd" 2>/dev/null
git_branch=$(git branch --show-current 2>/dev/null)

git_status=""
if [ -n "$git_branch" ]; then
    # Check for staged changes
    if ! git diff --cached --quiet 2>/dev/null; then
        git_status="+"
    fi
    # Check for unstaged changes
    if ! git diff --quiet 2>/dev/null; then
        git_status="${git_status}*"
    fi
    # Check for untracked files
    if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
        git_status="${git_status}?"
    fi
fi

status="$model"
dir_display="${cwd/#$HOME/~}"
status="$status | $dir_display"
[ -n "$git_branch" ] && status="$status | git:$git_branch$git_status"
[ -n "$context_remaining" ] && status="$status | context:${context_remaining}%"

echo "$status"
