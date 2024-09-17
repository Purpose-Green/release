#!/bin/bash
set -euo pipefail

function validate::no_diff_between_local_and_origin() {
  local source=$1
  local target=$2
  local force_deploy=$3

  # Check the status of the local branch compared to origin/main
  ahead_commits=$(git rev-list --count HEAD ^origin/main)

  if [[ "$ahead_commits" -gt 0 && "$force_deploy" == false ]]; then
    echo -e "${COLOR_RED}Error: Your $source is ahead of 'origin/$source'" \
      "by $ahead_commits commit(s)${COLOR_RESET}."

    echo -e "${COLOR_YELLOW}Please push your changes or reset \
your${COLOR_RESET} ${COLOR_ORANGE}$source${COLOR_RESET}."

    exit 1
  fi

  if [[ "$ahead_commits" -gt 0 && "$force_deploy" == true ]]; then
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
