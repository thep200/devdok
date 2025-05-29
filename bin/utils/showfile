#!/bin/bash

# Show file that match the extension in the current or specified directory
# Usage: showfile extension [path]
# Example: showfile php
function showfile() {
    local ext=$1
    local directory=${2:-.}

    if [[ -z "$ext" ]]; then
        echo "|-----------------------------------------------------|"
        echo "|Usage                 | showfile extension [path]    |"
        echo "|Ex Show current path  | showfile php                 |"
        echo "|Ex Show specific path | showfile php /path           |"
        echo "|-----------------------------------------------------|"
        return 1
    fi

    if [[ ! -d "$directory" ]]; then
        echo "Error: Directory '$directory' does not exist"
        return 1
    fi

    local count=$(find "$directory" -name "*.$ext" -type f | wc -l | tr -d ' ')
    if [[ $count -eq 0 ]]; then
        echo "No *.$ext files found in $directory"
        return 0
    fi

    find "$directory" -name "*.$ext" -type f -exec du -k {} + | \
    awk '{total+=$1} END{
        printf "|---------------------\n"
        printf "|Extension | '"$ext   \n"'"
        printf "|Count     | '"$count \n"'"
        printf "|Size (GB) | %.5f     \n", total/1024/1024
        printf "|---------------------\n"
    }'
}
