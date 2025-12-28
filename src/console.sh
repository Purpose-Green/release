#!/bin/bash
set -euo pipefail

# Console output helper functions
# Provides consistent, colored output across the application

# Prints an informational message in cyan
#
# Arguments:
#   $1 - message: The message to print
function console::info() {
  echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
}

# Prints a success message in green
#
# Arguments:
#   $1 - message: The message to print
function console::success() {
  echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
}

# Prints an error message in red
#
# Arguments:
#   $1 - message: The message to print
function console::error() {
  echo -e "${COLOR_RED}$1${COLOR_RESET}"
}

# Prints a warning message in yellow
#
# Arguments:
#   $1 - message: The message to print
function console::warn() {
  echo -e "${COLOR_YELLOW}$1${COLOR_RESET}"
}

# Checks if dry-run mode is enabled
#
# Returns:
#   0 if dry-run is enabled, 1 otherwise
function main::is_dry_run() {
  [[ "${DRY_RUN:-false}" == true ]]
}

# Strips the 'origin/' prefix from a branch name if present
#
# Arguments:
#   $1 - branch: The branch name (may include 'origin/' prefix)
#
# Output:
#   The branch name without the 'origin/' prefix
function git::strip_origin_prefix() {
  echo "${1#origin/}"
}

# Validates that Slack configuration is present
#
# Returns:
#   0 if both RELEASE_SLACK_CHANNEL_ID and RELEASE_SLACK_OAUTH_TOKEN are set
#   1 if either is missing
function env::is_slack_configured() {
  [[ -n "${RELEASE_SLACK_CHANNEL_ID:-}" && -n "${RELEASE_SLACK_OAUTH_TOKEN:-}" ]]
}
