#!/bin/bash
# shellcheck disable=SC2155
set -euo pipefail

function main::action() {
  local force_release=${1:-false}

  local source=${RELEASE_SOURCE_BRANCH:-main}
  local target=${RELEASE_TARGET_BRANCH:-prod}
  local develop=${RELEASE_DEVELOPMENT_BRANCH:-$source}

  validate::slack_configured "$force_release"

  # Ensure 'origin/' prefix
  if [[ $target != origin/* ]]; then
    target="origin/$target"
  fi

  main::render_steps "$source" "$target" "$develop"

  echo -e "${COLOR_PURPLE}------------------------------------------------------------------${COLOR_RESET}"
  main::check_current_branch_and_pull
  echo -e "${COLOR_BLUE}------------------------------------------------------------------${COLOR_RESET}"

  echo -e "Using source branch: ${COLOR_ORANGE}$source${COLOR_RESET}"
  validate::no_diff_between_local_and_origin "$source" "$target" "$force_release"

  local changed_files=$(git::changed_files "$target" "$source")
  local latest_tag=$(git::latest_tag)

  echo -e "Current latest tag: ${COLOR_CYAN}$latest_tag${COLOR_RESET}"
  local new_tag=$(release::generate_new_tag "$latest_tag" "$changed_files")
  compare::source_with_target "$source" "$target"

  # shellcheck disable=SC2116
  local question=$(echo "Force checkout ${COLOR_ORANGE}$target${COLOR_RESET}" \
    "and create new tag ${COLOR_CYAN}$new_tag${COLOR_RESET}... Ready to start?")
  io::confirm_or_exit "$question"

  if [ -z "$changed_files" ]; then
    echo -e "${COLOR_YELLOW}No files changed between branches, skipping merge.${COLOR_RESET}"
    exit 0
  fi

  env::run_extra_confirmation "$changed_files"
  env::run_extra_commands "$changed_files"

  git::force_checkout "$target"
  git::merge_source_to_target "$source" "$target"

  release::create_tag "$target" "$new_tag" "$changed_files"
  release::create_github_release "$latest_tag" "$new_tag"

  git::update_develop "$develop" "$target"
}

function main::check_current_branch_and_pull() {
  git::fetch_origin
  # Check if the branch is behind
  local status_output=$(git status)

  if [[ "$status_output" == *"Your branch is behind"* ]]; then
    echo -e "${COLOR_RED}Your local branch is not up to date!${COLOR_RESET}"
    local question=$(echo -e "Do you want to pull the latest changes?")
    io::confirm_or_exit "$question"
    echo -e "${COLOR_GREEN}Pulling updates...${COLOR_RESET}"
    git pull origin
  else
    echo -e "${COLOR_GREEN}Your branch is up to date!${COLOR_RESET}"
  fi

  git::status
}

function main::render_steps() {
  local source=$1
  local target=$2
  local develop=$3

  echo -e "This script will automate the release process and follow the following steps:"
  echo -e "- Define the branch to release: ${COLOR_YELLOW}$source${COLOR_RESET}"
  echo -e "- Fetch latest remote changes"
  echo -e "- Compare the branch with ${COLOR_YELLOW}$target${COLOR_RESET} to view the commits that will be released"
  echo -e "- Confirm you wish to proceed"
  echo -e "- Merge the selected branch (${COLOR_YELLOW}$source${COLOR_RESET}) to ${COLOR_YELLOW}$target${COLOR_RESET}"
  echo -e "- Create a tag and release"
  echo -e "- Notify via slack that a new release was created"
  echo -e "- Merge the target (${COLOR_YELLOW}$target${COLOR_RESET}) back to ${COLOR_YELLOW}$develop${COLOR_RESET}"
  echo -e ""
  echo -e "This script must use your local git environment."

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_BLUE}--dry-run enabled${COLOR_RESET}"
  fi
}
