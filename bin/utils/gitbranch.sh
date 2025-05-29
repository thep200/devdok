#!/bin/bash

# Listing branch name of git repository
# Usage: gitbranch
function gitbranch() {
    # Get all branch data first
    branch_data=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) - %(committerdate:relative)' | head -n 10)

    # Calculate max branch name length from actual data
    max_branch_length=$(echo "$branch_data" | awk -F' - ' '{print length($1)}' | sort -nr | head -1)

    # Set minimum width for "Branch Name" header (11 chars) and add padding
    header_length=11
    max_length=$((max_branch_length > header_length ? max_branch_length : header_length))

    # Calculate max commit date length from actual data
    max_commit_length=$(echo "$branch_data" | awk -F' - ' '{print length($2)}' | sort -nr | head -1)
    commit_header_length=11  # Length of "Last Commit"
    separator_length=$((max_commit_length > commit_header_length ? max_commit_length : commit_header_length))

    # Print table header
    printf "+%s+%s+\n" "$(printf '%*s' $((max_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((separator_length + 2)) | tr ' ' '-')"
    printf "| %-${max_length}s | %-${separator_length}s |\n" "Branch Name" "Last Commit"
    printf "+%s+%s+\n" "$(printf '%*s' $((max_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((separator_length + 2)) | tr ' ' '-')"

    # Print branch data
    echo "$branch_data" | while read -r line; do
        branch_name=$(echo "$line" | awk -F' - ' '{print $1}')
        commit_date=$(echo "$line" | awk -F' - ' '{print $2}')
        printf "| %-${max_length}s | %-${separator_length}s |\n" "$branch_name" "$commit_date"
    done

    # Print table footer
    printf "+%s+%s+\n" "$(printf '%*s' $((max_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((separator_length + 2)) | tr ' ' '-')"
}
