#!/bin/bash

# shellcheck disable=SC2155
function slack::notify() {
  local repo_info=$1
  local release_name=$2
  local changelog_url=$3
  local commits=$4

  local repo_url="https://github.com/$repo_info"
  local repo_name=$(echo "$repo_info" | cut -d'/' -f2)

  local slack_message=$(cat <<EOF
[
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "*<$repo_url|$repo_name>* :rocket: $release_name\n\n$commits\n<$changelog_url|Full changelog>"
    }
  }
]
EOF
)
  # Escaping quotes and newlines
  local slack_message_escaped="${slack_message//\"/\\\"}"
  slack_message_escaped="${slack_message_escaped//$'\n'/\\n}"

  local json_data="{\"channel\": \"$SLACK_CHANNEL_ID\", \"blocks\": \"$slack_message_escaped\"}"

  curl -s -o /dev/null -X POST https://slack.com/api/chat.postMessage \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "Authorization: Bearer $SLACK_OAUTH_TOKEN" \
    --data "$json_data"

  echo -e "${COLOR_GREEN}Notification sent via slack${COLOR_RESET}"
}
