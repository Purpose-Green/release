#!/bin/bash
set -euo pipefail

# shellcheck disable=SC2155
function main::action() {
  main::render_steps

  echo -e "${COLOR_PURPLE}============================================${COLOR_RESET}"
  git fetch origin
  git status
  echo -e "${COLOR_BLUE}============================================${COLOR_RESET}"

  echo -e "Using branch: ${COLOR_ORANGE}$SOURCE_BRANCH${COLOR_RESET}"
  validate::no_diff_between_local_and_origin "$SOURCE_BRANCH" "$TARGET_BRANCH"

  local changed_files=$(git diff --name-only "$TARGET_BRANCH".."$SOURCE_BRANCH")
  local latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v0")
  echo -e "Current latest tag: ${COLOR_CYAN}$latest_tag${COLOR_RESET}"
  local new_tag=$(release::generate_new_tag "$latest_tag" "$changed_files")
  main::compare_branch_with_target "$SOURCE_BRANCH" "$TARGET_BRANCH" "$changed_files"

  io::confirm_or_exit "Force checkout ${COLOR_ORANGE}origin/$TARGET_BRANCH${COLOR_RESET} and create new tag ${COLOR_CYAN}$new_tag${COLOR_RESET}... Ready to start?"
  main::force_checkout "$TARGET_BRANCH"

  if [ -n "$changed_files" ]; then
    echo -e "Merging ${COLOR_ORANGE}$SOURCE_BRANCH${COLOR_RESET} release to ${COLOR_ORANGE}$TARGET_BRANCH${COLOR_RESET}"
    git merge "$SOURCE_BRANCH"
  else
    echo -e "${COLOR_YELLOW}No files changed between branches, skipping merge.${COLOR_RESET}"
    exit 0
  fi

  if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Merge failed. Please resolve conflicts and try again.${COLOR_RESET}"
    exit 1
  fi

  git push origin "$TARGET_BRANCH" --no-verify

  release::create_tag "$new_tag" "$changed_files"
  release::create_github_release "$latest_tag" "$new_tag"

  echo -e "Merging ${COLOR_ORANGE}$TARGET_BRANCH${COLOR_RESET} back to ${COLOR_ORANGE}$DEVELOPMENT_BRANCH${COLOR_RESET} (increase the release contains hotfixes that are not in ${COLOR_ORANGE}$DEVELOPMENT_BRANCH${COLOR_RESET})"
  main::force_checkout "$DEVELOPMENT_BRANCH"

  git merge remotes/origin/"$TARGET_BRANCH"
  git push origin "$DEVELOPMENT_BRANCH" --no-verify

  echo -e "${COLOR_GREEN}Script completed${COLOR_RESET}"
  if [ -n "$DEPLOY_SUCCESSFUL_TEXT" ]; then
    echo -e "${DEPLOY_SUCCESSFUL_TEXT}"
  fi
}

function main::render_steps() {
  echo "This script will automate the release process and follow the following steps:"
  echo "- Fetch latest remote changes"
  echo "- Select a branch to deploy"
  echo "- Compare the branch with $TARGET_BRANCH to view the commits that will be deployed"
  echo "- Confirm you wish to proceed"
  echo "- Merge the selected branch to $TARGET_BRANCH"
  echo "- Create a release tag"
  echo "- Merge the selected branch to $DEVELOPMENT_BRANCH"
  echo ""
  echo "This script must use your local git environment. If you suspect your current branch is not clean please quit this script now. "
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
