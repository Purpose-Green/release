#!/bin/bash
set -euo pipefail

# Prompts user for confirmation and exits if not confirmed
#
# Arguments:
#   $1 - prompt: The question/prompt to display (supports color codes)
#
# Returns:
#   Continues if user enters 'y' or 'Y', exits with 1 otherwise
#
# Using local with command substitution is acceptable for readability
# shellcheck disable=SC2155
function io::confirm_or_exit() {
  local txt=$(echo -e "$1 [N/y]:")
  read -p "$txt " -r
  if [[ ! "${REPLY:0:1}" =~ ^[Yy]$ ]]; then
    echo "Input given not positive: '$REPLY' Exiting..."
    exit 1
  fi
}
