#!/bin/bash

# shellcheck disable=SC2155
function release::notify_via_slack() {
  local repo_info=$1
  local release_name=$2
  local changelog_url=$3
  local commits=$4

  local repo_url="https://github.com/$repo_info"
  local repo_name=$(echo "$repo_info" | cut -d'/' -f2)

  local slack_message=$(cat <<EOF
{
  "channel": "$SLACK_CHANNEL_ID",
  "unfurl_links": false,
  "unfurl_media": false,
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*<$repo_url|$repo_name>* :rocket: $release_name\n\n$commits\n<$changelog_url|Full changelog>"
      }
    }
  ]
}
EOF
)

  if [[ -n $SLACK_CHANNEL_ID && -n $SLACK_OAUTH_TOKEN ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      curl -X POST https://slack.com/api/chat.postMessage \
        -H "Content-Type: application/json; charset=utf-8" \
        -H "Authorization: Bearer $SLACK_OAUTH_TOKEN" \
        --data "$slack_message" \
        -s -o /tmp/slack-error.log
      echo -e "${COLOR_GREEN}Notification sent via slack${COLOR_RESET}"
    else
      echo -e "${COLOR_CYAN}--dry-run enabled. Skipping notify slack${COLOR_RESET}"
    fi
  fi
}
