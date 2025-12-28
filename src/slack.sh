#!/bin/bash
set -euo pipefail

# Cleanup function for temporary files
_SLACK_ERROR_LOG=""
function slack::cleanup() {
  if [[ -n "$_SLACK_ERROR_LOG" && -f "$_SLACK_ERROR_LOG" ]]; then
    rm -f "$_SLACK_ERROR_LOG"
  fi
}
trap slack::cleanup EXIT

# Sends a release notification to Slack
#
# Posts a formatted message to the configured Slack channel with release details,
# commit history, and changelog link.
#
# Arguments:
#   $1 - repo_info: Repository info in "owner/repo" format
#   $2 - release_name: The release name (e.g., "2024-01-15 #1")
#   $3 - changelog_url: URL to the full changelog comparison
#   $4 - commits: Newline-separated list of commits in this release
#   $5 - new_tag: The new version tag
#
# Returns:
#   0 on success, 1 on failure
#
# Using local with command substitution is acceptable for readability
# shellcheck disable=SC2155
function slack::notify() {
  if [[ -z "${RELEASE_SLACK_CHANNEL_ID:-}" || -z "${RELEASE_SLACK_OAUTH_TOKEN:-}" ]]; then
    echo -e "${COLOR_CYAN}Slack configuration missing." \
      "Check your .env for RELEASE_SLACK_CHANNEL_ID & RELEASE_SLACK_OAUTH_TOKEN${COLOR_RESET}"
    return
  fi

  local repo_info=$1
  local release_name=$2
  local changelog_url=$3
  local commits=$4
  local new_tag=$5

  local repo_url="https://github.com/$repo_info"
  local repo_name=$(echo "$repo_info" | cut -d'/' -f2)

  local repo_name_url="<$repo_url|$repo_name>"
  local release_name_url="<$repo_url/releases/tag/$new_tag|$release_name>"

  local slack_message=$(cat <<EOF
{
  "channel": "$RELEASE_SLACK_CHANNEL_ID",
  "unfurl_links": false,
  "unfurl_media": false,
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*$repo_name_url* :rocket: $release_name_url\n\n$commits\n<$changelog_url|Full changelog>"
      }
    }
  ]
}
EOF
)
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping notify slack${COLOR_RESET}"
    return
  fi

  _SLACK_ERROR_LOG=$(mktemp)
  if ! curl -X POST https://slack.com/api/chat.postMessage \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "Authorization: Bearer $RELEASE_SLACK_OAUTH_TOKEN" \
    --data "$slack_message" \
    -s -o "$_SLACK_ERROR_LOG"; then
    echo -e "${COLOR_RED}Failed to send Slack notification. Check $_SLACK_ERROR_LOG for details.${COLOR_RESET}"
    return 1
  fi

  echo -e "${COLOR_GREEN}Notification sent via slack${COLOR_RESET}"
}
