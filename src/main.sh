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
  git::fetch_origin
  git::status
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

function main::render_steps() {
  local source=$1
  local target=$2
  local develop=$3

  echo "This script will automate the release process and follow the following steps:"
  echo "- Define the branch to release: $source"
  echo "- Fetch latest remote changes"
  echo "- Compare the branch with $target to view the commits that will be released"
  echo "- Confirm you wish to proceed"
  echo "- Merge the selected branch to $target"
  echo "- Create a tag and release"
  echo "- Notify via slack that a new release was created"
  echo "- Merge the selected branch back to $develop"
  echo ""
  echo "This script must use your local git environment."

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_YELLOW}--dry-run enabled${COLOR_RESET}"
    return
  fi
}
