#!/bin/bash

function git::status() {
  git status
}

function git::fetch_origin() {
  git fetch origin
}

function git::pull_origin() {
  git pull origin
}

function git::changed_files() {
  git diff --name-only "$1".."$2"
}

function git::latest_tag() {
  git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v0"
}

function git::force_checkout() {
  local branch_name="${1#origin/}"  # Remove 'origin/' prefix if present

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping git fetch & checkout${COLOR_RESET}" \
      "${COLOR_ORANGE}origin/$branch_name${COLOR_RESET}"
    return
  fi

  git config advice.detachedHead false
  [ -f .git/hooks/post-checkout ] && mv .git/hooks/post-checkout .git/hooks/post-checkout.bak

  git::fetch_origin

  if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
    # If branch exists locally, force checkout it
    git checkout -f "$branch_name"
  else
    # If branch doesn't exist, create a new local branch from the remote
    git checkout -b "$branch_name" origin/"$branch_name"
  fi

  git::pull_origin

  [ -f .git/hooks/post-checkout.bak ] && mv .git/hooks/post-checkout.bak .git/hooks/post-checkout
  git config advice.detachedHead true
}

function git::update_develop() {
  local develop=$1
  local target=$2

  echo -e "Merging ${COLOR_ORANGE}$target${COLOR_RESET} back to" \
    "${COLOR_ORANGE}$develop${COLOR_RESET} (increase the release contains hotfixes" \
    "that are not in ${COLOR_ORANGE}$develop${COLOR_RESET})"

  git::force_checkout "$develop"
  git::merge_source_to_target "$target" "$develop"
}

function git::merge_source_to_target() {
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
