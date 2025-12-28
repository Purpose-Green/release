#!/bin/bash
set -euo pipefail

# Validates that local branch is not ahead of origin
#
# If the local branch has unpushed commits, prompts for confirmation (with --force)
# or exits with an error.
#
# Arguments:
#   $1 - source: The source branch name
#   $2 - target: The target branch name
#   $3 - force_release: Whether to allow ahead commits ("true" or "false")
#
# Returns:
#   Exits with 1 if ahead and not forced, continues otherwise
function validate::no_diff_between_local_and_origin() {
  local source=$1
  local target=$2
  local force_release=$3

  # Check the status of the local branch compared to origin/main
  ahead_commits=$(git rev-list --count HEAD ^origin/main)

  if [[ "$ahead_commits" -gt 0 && "$force_release" == false ]]; then
    echo -e "${COLOR_RED}Error: Your $source is ahead of 'origin/$source'" \
      "by $ahead_commits commit(s)${COLOR_RESET}."

    echo -e "${COLOR_YELLOW}Please push your changes or reset \
your${COLOR_RESET} ${COLOR_ORANGE}$source${COLOR_RESET}."

    exit 1
  fi

  if [[ "$ahead_commits" -gt 0 && "$force_release" == true ]]; then
    echo -e "Your local ${COLOR_ORANGE}$source${COLOR_RESET} is ahead" \
      "of ${COLOR_ORANGE}origin/$source${COLOR_RESET}" \
      "by ${COLOR_RED}$ahead_commits${COLOR_RESET} commit(s)${COLOR_RESET}."

    # shellcheck disable=SC2155
    # shellcheck disable=SC2116
    local question=$(echo "${COLOR_YELLOW}Are you sure you want to push them" \
      "to 'origin/$target' as part of the release?${COLOR_RESET}")

    io::confirm_or_exit "$question"
  fi
}
# Validates that Slack credentials are configured and working
#
# Tests the Slack OAuth token by making an auth.test API call.
# Skipped if force_release is true.
#
# Arguments:
#   $1 - force_release: Whether to skip validation ("true" or "false")
#
# Returns:
#   Exits with 1 if Slack is not configured or auth fails
#
# Using local with command substitution is acceptable for readability
# shellcheck disable=SC2155
function validate::slack_configured() {
  local force_release=$1

  if [[ $force_release == true ]]; then
    return
  fi

  # Check if SLACK_CHANNEL_ID and SLACK_OAUTH_TOKEN are set, and exit if they are missing
  if [[ -z "${RELEASE_SLACK_CHANNEL_ID:-}" || -z "${RELEASE_SLACK_OAUTH_TOKEN:-}" ]]; then
    echo -e "${COLOR_RED}Slack configuration missing.${COLOR_RESET}" \
      "Check your .env for RELEASE_SLACK_CHANNEL_ID & RELEASE_SLACK_OAUTH_TOKEN"
    exit 1
  fi

  # Make the curl request and capture the response
  local response=$(curl -s -d "token=$RELEASE_SLACK_OAUTH_TOKEN" https://slack.com/api/auth.test)

  # Extract the "ok" field from the JSON response using grep pattern matching
  # This avoids requiring jq as a dependency
  local ok=$(echo "$response" | grep -o '"ok":true')

  # Check if the "ok" field is found and equals true
  if [[ -z $ok ]]; then
    echo -e "${COLOR_RED}Slack auth test failed. Please check your RELEASE_SLACK_OAUTH_TOKEN.${COLOR_RESET}"
    exit 1
  fi
}
