#!/bin/bash

# Fetch and display the latest git tags, and optionally create new ones
# Usage: gittag [pattern]
function gittag() {
    # Protected tag prefixes that require confirmation
    local protected_prefixes=("live" "prod" "stable")
    local green_arrow="\033[32m➤\033[0m"
    local success_icon="🎉"
    local error_icon="❌"

    # Fetch latest tags
    git fetch --tags > /dev/null 2>&1
    local latest_tags=$(git tag --sort=-creatordate | grep "$1" | head -n 7)
    echo "$latest_tags"

    # Enter new tag name or skip
    echo ""
    echo -n "${green_arrow} Type new tag (Enter to skip): "
    read new_tag

    if [ -n "$new_tag" ]; then
        # Check if tag already exists
        if git tag -l | grep -q "^$new_tag$"; then
            echo "${green_arrow} Tag \033[32m$new_tag\033[0m already exists"
            return 1
        fi

        # Check if tag starts with any protected prefix
        local needs_confirm=false
        for prefix in "${protected_prefixes[@]}"; do
            if [[ "$new_tag" =~ ^"$prefix" ]]; then
                needs_confirm=true
                break
            fi
        done

        # Need confirm
        if [ "$needs_confirm" = true ]; then
            echo -n "${green_arrow} Create \033[32m$new_tag\033[0m tag? (y/n): "
            read confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo "${error_icon} Cancelled"
                return 1
            fi
        fi

        # Create and push the tag
        git tag "$new_tag"
        if [ $? -eq 0 ]; then
            git push origin "$new_tag"
            echo "${success_icon} Created tag \033[32m$new_tag\033[0m"
        else
            echo "${error_icon} Failed to create tag \033[32m$new_tag\033[0m"
            return 1
        fi
    fi
}
