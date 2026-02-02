#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
context_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

cd "$cwd" 2>/dev/null
git_branch=$(git branch --show-current 2>/dev/null)

git_status=""
if [ -n "$git_branch" ]; then
    # Calculate line additions/deletions (staged + unstaged)
    diff_stats=$(git diff --numstat HEAD 2>/dev/null | awk '{add+=$1; del+=$2} END {if(add>0 || del>0) print add, del}')
    if [ -n "$diff_stats" ]; then
        additions=$(echo "$diff_stats" | cut -d' ' -f1)
        deletions=$(echo "$diff_stats" | cut -d' ' -f2)
        git_status=" \033[32m+${additions}\033[0m \033[31m-${deletions}\033[0m"
    fi
fi

status="$model"
dir_display="${cwd/#$HOME/~}"
status="$status | $dir_display"
[ -n "$git_branch" ] && status="$status | git:$git_branch$git_status"
[ -n "$context_remaining" ] && status="$status | context:${context_remaining}%"

echo -e "$status"
