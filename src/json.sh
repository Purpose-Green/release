#!/bin/bash
# shellcheck disable=SC2155 - Using local with command substitution is acceptable for readability
set -euo pipefail

# Extracts a value from a simple JSON object by matching a file path
#
# This function progressively searches from the full path up to parent directories
# until it finds a matching key in the JSON object.
#
# Arguments:
#   $1 - json_str: A JSON object string (e.g., '{"src/dev": "message"}')
#   $2 - filepath: The file path to look up
#
# Output:
#   The value associated with the matching path, or empty if not found
#
# Example:
#   json::parse_text '{"src/dev": "Are you sure?"}' "src/dev/file.sh"
#   # Returns: "Are you sure?" (matches parent directory "src/dev")
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
