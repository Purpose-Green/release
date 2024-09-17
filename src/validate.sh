#!/bin/bash
set -euo pipefail

function validate::no_diff_between_local_and_origin() {
  local SOURCE_BRANCH=$1
  local TARGET_BRANCH=$2
  local force_deploy=$3

  # Check the status of the local branch compared to origin/main
  ahead_commits=$(git rev-list --count HEAD ^origin/main)

  if [[ "$ahead_commits" -gt 0 && "$force_deploy" == false ]]; then
    echo -e "${COLOR_RED}Error: Your $SOURCE_BRANCH is ahead of 'origin/$SOURCE_BRANCH'" \
      "by $ahead_commits commit(s)${COLOR_RESET}."

    echo -e "${COLOR_YELLOW}Please push your changes or reset \
your${COLOR_RESET} ${COLOR_ORANGE}$SOURCE_BRANCH${COLOR_RESET}."

    exit 1
  fi

  if [[ "$ahead_commits" -gt 0 && "$force_deploy" == true ]]; then
    echo -e "Your local ${COLOR_ORANGE}$SOURCE_BRANCH${COLOR_RESET} is ahead" \
      "of ${COLOR_ORANGE}origin/$SOURCE_BRANCH${COLOR_RESET}" \
      "by ${COLOR_RED}$ahead_commits${COLOR_RESET} commit(s)${COLOR_RESET}."

    io::confirm_or_exit "${COLOR_YELLOW}Are you sure you want to push them" \
      "to 'origin/$TARGET_BRANCH' as part of the release?${COLOR_RESET}"
  fi
}
