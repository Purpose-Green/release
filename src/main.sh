#!/bin/bash
set -euo pipefail

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

# shellcheck disable=SC2155
function main::action() {
  main::render_steps

  echo -e "${COLOR_PURPLE}============================================${COLOR_RESET}"
  git fetch origin
  git status
  echo -e "${COLOR_BLUE}============================================${COLOR_RESET}"

  echo -e "Using branch: ${COLOR_ORANGE}$SOURCE_BRANCH${COLOR_RESET}"
  main::validate_no_diff_between_local_and_origin "$SOURCE_BRANCH" "$TARGET_BRANCH"

  local changed_files=$(git diff --name-only "$TARGET_BRANCH".."$SOURCE_BRANCH")
  local latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v0")
  echo -e "Current latest tag: ${COLOR_CYAN}$latest_tag${COLOR_RESET}"
  local new_tag=$(main::generate_new_tag "$latest_tag" "$changed_files")
  main::compare_branch_with_target "$SOURCE_BRANCH" "$TARGET_BRANCH" "$changed_files"

  main::confirm_or_exit "Force checkout ${COLOR_ORANGE}origin/$TARGET_BRANCH${COLOR_RESET} and create new tag ${COLOR_CYAN}$new_tag${COLOR_RESET}... Ready to start?"
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

  main::create_tag "$new_tag" "$changed_files"
  main::create_github_release "$latest_tag" "$new_tag"

  echo -e "Merging ${COLOR_ORANGE}$TARGET_BRANCH${COLOR_RESET} back to ${COLOR_ORANGE}$DEVELOPMENT_BRANCH${COLOR_RESET} (increase the release contains hotfixes that are not in ${COLOR_ORANGE}$DEVELOPMENT_BRANCH${COLOR_RESET})"
  main::force_checkout "$DEVELOPMENT_BRANCH"

  git merge remotes/origin/"$TARGET_BRANCH"
  git push origin "$DEVELOPMENT_BRANCH" --no-verify

  echo -e "${COLOR_GREEN}Script completed${COLOR_RESET}"
  if [ -n "$DEPLOY_SUCCESSFUL_TEXT" ]; then
    echo -e "${DEPLOY_SUCCESSFUL_TEXT}"
  fi
}

function main::confirm_or_exit() {
  # shellcheck disable=SC2155
  local txt=$(echo -e "$1 (Y/n):")
  read -p "$txt " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1
  fi
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

function main::render_changed_files() {
  local source=$1
  local target=$2

  local added_files=()
  local modified_files=()
  local deleted_files=()

  # Collect files based on their status
  while read status file; do
      case "$status" in
          A) # Added (created)
              added_files+=("$file")
              ;;
          M) # Modified (updated)
              modified_files+=("$file")
              ;;
          D) # Deleted
              deleted_files+=("$file")
              ;;
      esac
  done < <(git diff --name-status "$target".."$source")

  # Output the files, sorted by status

  # Added (created) files
  for file in "${added_files[@]}"; do
      echo -e "${COLOR_GREEN}+ $file${COLOR_RESET}"
  done

  # Modified (updated) files
  for file in "${modified_files[@]}"; do
      echo -e "${COLOR_YELLOW}~ $file${COLOR_RESET}"
  done

  # Deleted files
  for file in "${deleted_files[@]}"; do
      echo -e "${COLOR_RED}- $file${COLOR_RESET}"
  done
}

function main::compare_branch_with_target() {
  local source=$1
  local target=$2
  local changed_files=$3

  echo -e "Comparing ${COLOR_ORANGE}$source${COLOR_RESET} with ${COLOR_ORANGE}$target${COLOR_RESET}"
  echo -e "${COLOR_BLUE}============================================${COLOR_RESET}"
  echo -e "Commits to include in the release (into ${COLOR_ORANGE}$target${COLOR_RESET}):"
  echo "$(git log --color --oneline origin/"$target".."$source")"
  echo -e "${COLOR_BLUE}============================================${COLOR_RESET}"
  echo -e "Changed files between '${COLOR_ORANGE}$target${COLOR_RESET}' and '${COLOR_ORANGE}$source${COLOR_RESET}':"
  main::render_changed_files "$source" "$target"
  echo -e "${COLOR_PURPLE}============================================${COLOR_RESET}"
}

# shellcheck disable=SC2155
function main::generate_release_name() {
  local current_date=$(date +"%Y-%m-%d")
  # Use xargs to trim leading/trailing whitespace
  local latest_release=$(gh release list | head -n 1 | awk -F 'Latest' '{print $1}' | xargs)

  local release_number
  if [[ "$latest_release" =~ ^$current_date\ #([0-9]+)$ ]]; then
    release_number=$((BASH_REMATCH[1] + 1))
  else
    release_number=1
  fi

  echo "$current_date #$release_number"
}

function main::generate_new_tag() {
  local latest_tag=$1
  local changed_files=$2

  local tag_number
  if [[ $latest_tag =~ ^v([0-9]+)$ ]]; then
    tag_number="${BASH_REMATCH[1]}"
    tag_number=$((tag_number + 1))
  else
    tag_number=1
  fi

  echo "v$tag_number"
}

function main::create_tag() {
  local new_tag=$1
  local changed_files=$2
  git tag -a "$new_tag" -m "Release $new_tag

Changes:
$changed_files"

  git push origin --tags --no-verify
}

# shellcheck disable=SC2155
function main::create_github_release() {
  if [ "$GH_CLI_INSTALLED" = false ]; then
    return
  fi

  local previous_tag=$1
  local new_tag=$2

  if [ "$previous_tag" = "v0" ]; then
    previous_tag="main"
  fi

  local commits=$(git log --oneline "$previous_tag".."$new_tag")
  local release_name=$(main::generate_release_name)
  local remote_url=$(git remote get-url origin)
  local repo_info=$(echo "$remote_url" | sed -E 's|git@github\.com:||; s|\.git$||')

  local changelog_url="https://github.com/$repo_info/compare/$previous_tag...$new_tag"
  local full_changelog="**Full Changelog**: $changelog_url"
  gh release create "$new_tag" \
    --title "$release_name" \
    --notes "$(echo -e "$commits\n\n$full_changelog")"
}

function main::validate_no_diff_between_local_and_origin() {
  local SOURCE_BRANCH=$1
  local target_branch=$2
  # Check the status of the local branch compared to origin/main
  ahead_commits=$(git rev-list --count HEAD ^origin/main)

  if [[ "$ahead_commits" -gt 0 && "$FORCE_DEPLOY" == false ]]; then
    echo -e "${COLOR_RED}Error: Your $SOURCE_BRANCH is ahead of 'origin/main' by $ahead_commits commit(s)${COLOR_RESET}."
    echo -e "${COLOR_YELLOW}Please push your changes or reset your${COLOR_RESET} ${COLOR_ORANGE}$SOURCE_BRANCH${COLOR_RESET}."
    exit 1
  fi
  if [[ "$ahead_commits" -gt 0 && "$FORCE_DEPLOY" == true ]]; then
    echo -e "Your local ${COLOR_ORANGE}$SOURCE_BRANCH${COLOR_RESET} is ahead of ${COLOR_ORANGE}origin/$SOURCE_BRANCH${COLOR_RESET} by ${COLOR_RED}$ahead_commits${COLOR_RESET} commit(s)${COLOR_RESET}."
    main::confirm_or_exit "${COLOR_YELLOW}Are you sure you want to push them to 'origin/$target_branch' as part of the release?${COLOR_RESET}"
  fi
}
