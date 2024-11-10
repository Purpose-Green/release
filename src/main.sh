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
  git fetch origin
  git status
  echo -e "${COLOR_BLUE}------------------------------------------------------------------${COLOR_RESET}"

  echo -e "Using source branch: ${COLOR_ORANGE}$source${COLOR_RESET}"
  validate::no_diff_between_local_and_origin "$source" "$target" "$force_release"

  local changed_files=$(git diff --name-only "$target".."$source")
  local latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v0")

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

  main::force_checkout "$target"
  main::merge_source_to_target "$source" "$target"

  release::create_tag "$target" "$new_tag" "$changed_files"
  release::create_github_release "$latest_tag" "$new_tag"

  main::update_develop "$develop" "$target"
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

function main::update_develop() {
  local develop=$1
  local target=$2

  echo -e "Merging ${COLOR_ORANGE}$target${COLOR_RESET} back to" \
    "${COLOR_ORANGE}$develop${COLOR_RESET} (increase the release contains hotfixes" \
    "that are not in ${COLOR_ORANGE}$develop${COLOR_RESET})"

  main::force_checkout "$develop"
  main::merge_source_to_target "$target" "$develop"
}

function main::merge_source_to_target() {
  local source=$1
  local target=$2

  echo -e "Merging ${COLOR_ORANGE}$source${COLOR_RESET} release to ${COLOR_ORANGE}$target${COLOR_RESET}"

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping git merge ($source into $target)${COLOR_RESET}"
    return
  fi

  if ! git merge "$source"; then
    echo -e "${COLOR_RED}Merge failed. Please resolve conflicts and try again.${COLOR_RESET}"
    exit 1
  fi

  git push origin "$target" --no-verify

}

function main::force_checkout() {
  local branch_name="${1#origin/}"  # Remove 'origin/' prefix if present

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping git fetch & checkout${COLOR_RESET}" \
      "${COLOR_ORANGE}origin/$branch_name${COLOR_RESET}"
    return
  fi

  git config advice.detachedHead false
  [ -f .git/hooks/post-checkout ] && mv .git/hooks/post-checkout .git/hooks/post-checkout.bak

  git fetch origin

  if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
    # If branch exists locally, force checkout it
    git checkout -f "$branch_name"
  else
    # If branch doesn't exist, create a new local branch from the remote
    git checkout -b "$branch_name" origin/"$branch_name"
  fi

  [ -f .git/hooks/post-checkout.bak ] && mv .git/hooks/post-checkout.bak .git/hooks/post-checkout
  git config advice.detachedHead true
}
