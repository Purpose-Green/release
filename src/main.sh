#!/bin/bash
set -euo pipefail

# shellcheck disable=SC2155
function main::action() {
  local source=${1:-main}
  local target=${2:-prod}
  local development=${3:-1:-}
  local force_deploy=${4:-false}

  main::render_steps "$source" "$target" "$development"

  echo -e "${COLOR_PURPLE}------------------------------------------------------------------${COLOR_RESET}"
  git fetch origin
  git status
  echo -e "${COLOR_BLUE}------------------------------------------------------------------${COLOR_RESET}"

  echo -e "Using source branch: ${COLOR_ORANGE}$source${COLOR_RESET}"
  validate::no_diff_between_local_and_origin "$source" "$target" "$force_deploy"

  local changed_files=$(git diff --name-only "$target".."$source")
  local latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v0")

  echo -e "Current latest tag: ${COLOR_CYAN}$latest_tag${COLOR_RESET}"
  local new_tag=$(release::generate_new_tag "$latest_tag" "$changed_files")
  compare::source_with_target "$source" "$target"

  # shellcheck disable=SC2116
  local question=$(echo "Force checkout ${COLOR_ORANGE}origin/$target${COLOR_RESET}" \
    "and create new tag ${COLOR_CYAN}$new_tag${COLOR_RESET}... Ready to start?")
  io::confirm_or_exit "$question"

  if [ -z "$changed_files" ]; then
    echo -e "${COLOR_YELLOW}No files changed between branches, skipping merge.${COLOR_RESET}"
    exit 0
  fi

  main::force_checkout "$target"
  main::merge_source_to_target "$source" "$target"

  release::create_tag "$new_tag" "$changed_files"
  release::create_github_release "$latest_tag" "$new_tag"

  main::update_development "$development" "$target"
}

function main::render_steps() {
  local source=$1
  local target=$1
  local development=$2

  echo "This script will automate the release process and follow the following steps:"
  echo "- Define the branch to deploy: $source"
  echo "- Fetch latest remote changes"
  echo "- Compare the branch with $target to view the commits that will be deployed"
  echo "- Confirm you wish to proceed"
  echo "- Merge the selected branch to $target"
  echo "- Create a tag and release"
  echo "- Merge the selected branch back to $development"
  echo ""
  echo "This script must use your local git environment."
}

function main::update_development() {
  local development=$1
  local target=$2

  echo -e "Merging ${COLOR_ORANGE}$target${COLOR_RESET} back to" \
    "${COLOR_ORANGE}$development${COLOR_RESET} (increase the release contains hotfixes" \
    "that are not in ${COLOR_ORANGE}$development${COLOR_RESET})"

  main::force_checkout "$development"
  main::merge_source_to_target "remotes/origin/$target" "$development"

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
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping git checkout${COLOR_RESET}"
    return
  fi

  git config advice.detachedHead false
  [ -f .git/hooks/post-checkout ] && mv .git/hooks/post-checkout .git/hooks/post-checkout.bak
  git checkout -f origin/"$1"
  git branch -D "$1"
  git checkout -b "$1" origin/"$1"
  [ -f .git/hooks/post-checkout.bak ] && mv .git/hooks/post-checkout.bak .git/hooks/post-checkout
  git config advice.detachedHead true
}
