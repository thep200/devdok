#!/bin/bash

# Listing branch name of git repository
# Usage: gitbranch
function gitbranch() {
    max_length=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | awk '{ print length, $0 }' | sort -nr | head -1 | awk '{ print $1 }')
    ((max_length = max_length > 25 ? max_length : 25))
    printf "%-${max_length}s-+-%s\n" "$(printf '%*s' $max_length | tr ' ' '-')" "-------------------"
    printf "%-${max_length}s | %s\n" "Branch Name" "Last Commit"
    printf "%-${max_length}s-+-%s\n" "$(printf '%*s' $max_length | tr ' ' '-')" "-------------------"
    git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) - %(committerdate:relative)' | head -n 10 | while read -r line; do
        branch_name=$(echo "$line" | awk -F' - ' '{print $1}')
        commit_date=$(echo "$line" | awk -F' - ' '{print $2}')
        printf "%-${max_length}s | %s\n" "$branch_name" "$commit_date"
    done
    printf "%-${max_length}s-+-%s\n" "$(printf '%*s' $max_length | tr ' ' '-')" "-------------------"
}
