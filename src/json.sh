#!/bin/bash
# shellcheck disable=SC2155
set -euo pipefail

# Render the value str where the key is matching on the given json
#
# $1 full json as str
# $2 the filepath
#
# Example: '{"src/dev": "are you sure you want to change the files in this dir?"}'
function json::parse_text() {
    local json_str="$1"
    local filepath="$2"

    # Start with the full path and progressively reduce it to parent directories
    local dir_path="$filepath"

    while [[ -n "$dir_path" ]]; do
        # Escape special characters in the directory path for `sed`
        local escaped_dir_path=$(echo "$dir_path" | sed 's/[\/&]/\\&/g')

        # Extract and return the message for the current directory path if it exists in the JSON string
        local text=$(echo "$json_str" | sed -n "s/.*\"$escaped_dir_path\":\"\([^\"]*\)\".*/\1/p")

        if [[ -n "$text" ]]; then
            echo "$text"
            return
        fi

        # Remove the last directory level
        dir_path=$(dirname "$dir_path")

        # Break if we reach the root
        if [[ "$dir_path" == "." ]]; then
            break
        fi
    done
}
