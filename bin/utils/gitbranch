#!/bin/bash

# Listing branch name of git repository
# Usage: gitbranch
function gitbranch() {
    # Get current branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Get all branch data first
    branch_data=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) - %(committerdate:relative)' | head -n 10)

    # Calculate max branch name length from actual data
    max_branch_length=$(echo "$branch_data" | awk -F' - ' '{print length($1)}' | sort -nr | head -1)

    # Set minimum width for "Branch Name" header (11 chars) and add padding
    header_length=4  # Length of "Name"
    max_length=$((max_branch_length > header_length ? max_branch_length : header_length))

    # Calculate max commit date length from actual data
    max_commit_length=$(echo "$branch_data" | awk -F' - ' '{print length($2)}' | sort -nr | head -1)
    commit_header_length=4  # Length of "Time"
    separator_length=$((max_commit_length > commit_header_length ? max_commit_length : commit_header_length))

    # Calculate Status column width dynamically
    status_header_length=6  # Length of "Status"
    max_status_length=7     # Length of "Current" (longest status)
    status_length=$((max_status_length > status_header_length ? max_status_length : status_header_length))

    # Print table header
    printf "+%s+%s+%s+\n" "$(printf '%*s' $((max_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((separator_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((status_length + 2)) | tr ' ' '-')"
    printf "| %-${max_length}s | %-${separator_length}s | %-${status_length}s |\n" "Name" "Time" "Status"
    printf "+%s+%s+%s+\n" "$(printf '%*s' $((max_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((separator_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((status_length + 2)) | tr ' ' '-')"

    # Print branch data
    echo "$branch_data" | while read -r line; do
        branch_name=$(echo "$line" | awk -F' - ' '{print $1}')
        commit_date=$(echo "$line" | awk -F' - ' '{print $2}')

        # Check if branch is merged
        if [ "$branch_name" = "$current_branch" ]; then
            branch_status="Current"
        else
            merge_base=$(git merge-base "$current_branch" "$branch_name" 2>/dev/null)
            branch_commit=$(git rev-parse "$branch_name" 2>/dev/null)
            if [ "$merge_base" = "$branch_commit" ]; then
                branch_status="Merged"
            else
                branch_status="Active"
            fi
        fi

        printf "| %-${max_length}s | %-${separator_length}s | %-${status_length}s |\n" "$branch_name" "$commit_date" "$branch_status"
    done

    # Print table footer
    printf "+%s+%s+%s+\n" "$(printf '%*s' $((max_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((separator_length + 2)) | tr ' ' '-')" "$(printf '%*s' $((status_length + 2)) | tr ' ' '-')"
}
