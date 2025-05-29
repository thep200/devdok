#!/bin/bash

# Git push with safety checks and automation
function gitpush() {
    local commit_message="$1"

    # Check if commit message is provided
    if [[ -z "$commit_message" ]]; then
        echo "Error: Commit message is required"
        echo "Usage: gitpush \"your commit message\""
        return 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi

    # Get current branch name
    local current_branch=$(git branch --show-current)
    echo ""
    echo "Step 1: Current branch: \033[1;32m$current_branch\033[0m"
    echo ""

    # List of protected branches that need confirmation
    local protected_branches=("main" "master" "staging" "stg")
    local is_protected=false
    for branch in "${protected_branches[@]}"; do
        if [[ "$current_branch" == "$branch" ]]; then
            is_protected=true
            break
        fi
    done

    # Show changes summary before adding (non-interactive)
    echo "Step 2: Changes to be added"
    git --no-pager diff --stat
    echo ""

    # Auto git add all
    echo "Step 3: Adding all changes..."
    git add .
    echo ""

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo "No changes to commit"
        return 0
    fi

    # Commit with message
    echo "Step 4: Committing changes with message: \"$commit_message\""
    if ! git commit -m "$commit_message"; then
        echo "Error: Failed to commit changes"
        return 1
    fi
    echo ""

    # Check for protected branch and ask for confirmation
    if [[ "$is_protected" == true ]]; then
        echo -n "Are you sure to push to \033[1;31m$current_branch\033[0m branch? (y/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Push cancelled"
            return 0
        fi
        echo ""
    fi

    # Fetch latest changes to check for conflicts
    echo "Step 5: Fetching from origin..."
    git fetch origin
    echo ""

    # Check for merge conflicts before pushing
    if git rev-parse --verify "origin/$current_branch" > /dev/null 2>&1; then
        # Check if we need to merge
        local behind_count=$(git rev-list --count HEAD..origin/$current_branch)
        if [[ $behind_count -gt 0 ]]; then
            echo "Your branch is behind \033[1;33morigin/$current_branch\033[0m by $behind_count commits"
            echo "Attempting to pull and merge..."

            if ! git pull origin "$current_branch"; then
                echo ""
                echo "Merge conflicts detected!"
                return 1
            fi
            echo ""
        fi
    fi

    # Push to origin
    echo "Step 6: Pushing to \033[1;34morigin/$current_branch\033[0m..."
    if git push origin "$current_branch"; then
        echo "Successfully pushed to \033[1;34morigin/$current_branch\033[0m"
    else
        echo "Failed to push"
        return 1
    fi
    echo ""
}
