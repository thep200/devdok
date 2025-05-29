#!/bin/bash

# Fetch and display the latest git tags
# Usage: gittag [pattern]
function gittag() {
    git fetch --tags
    git tag --sort=-creatordate | grep "$1" | head -n 5
}
