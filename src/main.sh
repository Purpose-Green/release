#!/bin/bash
set -euo pipefail

# shellcheck disable=SC2155
function main::action() {
  local source_branch=${1:-main}
  local target_branch=${2:-prod}
  local development_branch=${3:-1:-}
  local force_deploy=${4:-false}
  local deploy_successful_text=${5:-}

  main::render_steps "$source_branch" "$development_branch"

  echo -e "${COLOR_PURPLE}============================================${COLOR_RESET}"
  git fetch origin
  git status
  echo -e "${COLOR_BLUE}============================================${COLOR_RESET}"

  echo -e "Using branch: ${COLOR_ORANGE}$source_branch${COLOR_RESET}"
  validate::no_diff_between_local_and_origin "$source_branch" "$target_branch" "$force_deploy"

  local changed_files=$(git diff --name-only "$target_branch".."$source_branch")
  local latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v0")
  echo -e "Current latest tag: ${COLOR_CYAN}$latest_tag${COLOR_RESET}"
  local new_tag=$(release::generate_new_tag "$latest_tag" "$changed_files")
  main::compare_branch_with_target "$source_branch" "$target_branch" "$changed_files"

  io::confirm_or_exit "Force checkout ${COLOR_ORANGE}origin/$target_branch${COLOR_RESET}" \
    "and create new tag ${COLOR_CYAN}$new_tag${COLOR_RESET}... Ready to start?"
  main::force_checkout "$target_branch"

  if [ -n "$changed_files" ]; then
    echo -e "Merging ${COLOR_ORANGE}$source_branch${COLOR_RESET} release to ${COLOR_ORANGE}$target_branch${COLOR_RESET}"
    git merge "$source_branch"
  else
    echo -e "${COLOR_YELLOW}No files changed between branches, skipping merge.${COLOR_RESET}"
    exit 0
  fi

  if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Merge failed. Please resolve conflicts and try again.${COLOR_RESET}"
    exit 1
  fi

  git push origin "$target_branch" --no-verify

  release::create_tag "$new_tag" "$changed_files"
  release::create_github_release "$latest_tag" "$new_tag"

  echo -e "Merging ${COLOR_ORANGE}$target_branch${COLOR_RESET} back to" \
    "${COLOR_ORANGE}$development_branch${COLOR_RESET} (increase the release contains hotfixes" \
    "that are not in ${COLOR_ORANGE}$development_branch${COLOR_RESET})"

  main::force_checkout "$development_branch"

  git merge remotes/origin/"$target_branch"
  git push origin "$development_branch" --no-verify

  echo -e "${COLOR_GREEN}Script completed${COLOR_RESET}"
  if [ -n "$deploy_successful_text" ]; then
    echo -e "$deploy_successful_text"
  fi
}

function main::render_steps() {
  local target_branch=$1
  local development_branch=$2

  echo "This script will automate the release process and follow the following steps:"
  echo "- Fetch latest remote changes"
  echo "- Select a branch to deploy"
  echo "- Compare the branch with $target_branch to view the commits that will be deployed"
  echo "- Confirm you wish to proceed"
  echo "- Merge the selected branch to $target_branch"
  echo "- Create a tag and release"
  echo "- Merge the selected branch back to $development_branch"
  echo ""
  echo "This script must use your local git environment."
}

function main::force_checkout() {
  git config advice.detachedHead false
  [ -f .git/hooks/post-checkout ] && mv .git/hooks/post-checkout .git/hooks/post-checkout.bak
  git checkout -f origin/"$1"
  git branch -D "$1"
  git checkout -b "$1" origin/"$1"
  [ -f .git/hooks/post-checkout.bak ] && mv .git/hooks/post-checkout.bak .git/hooks/post-checkout
  git config advice.detachedHead true
}
