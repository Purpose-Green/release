#!/bin/bash
set -euo pipefail

# Using local with command substitution is acceptable for readability
# shellcheck disable=SC2155

# Displays the current git status
function git::status() {
  git status
}

# Fetches the latest changes from the origin remote
function git::fetch_origin() {
  git fetch origin
}

# Pulls latest changes from origin with fast-forward only
#
# Arguments:
#   $1 - branch: (optional) The branch to pull. If not specified, uses upstream or current branch
function git::pull_origin() {
  local branch="${1:-}"

  if [[ -z "$branch" ]]; then
    # If an upstream is configured, just pull with ff-only
    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
      git pull --ff-only
      return
    fi

    # Fallback to current branch name against origin
    branch="$(git rev-parse --abbrev-ref HEAD)"
  fi

  git pull --ff-only origin "$branch"
}

# Lists files that have changed between two refs
#
# Arguments:
#   $1 - from_ref: The starting reference (e.g., origin/prod)
#   $2 - to_ref: The ending reference (e.g., main)
#
# Output:
#   List of changed file paths, one per line
function git::changed_files() {
  git diff --name-only "$1".."$2"
}

# Extracts the highest version number from a list of git tags
#
# This function only matches simple version tags in the format "vN" where N is a number.
# Semantic versioning tags (v1.2.3) are intentionally ignored to maintain simple sequential versioning.
#
# Arguments:
#   $1 - tags: Newline-separated list of git tags
#
# Output:
#   The highest version number found (without 'v' prefix), or 0 if none found
#
# Example:
#   git::extract_max_version_number "v1\nv2\nv3" # outputs: 3
function git::extract_max_version_number() {
  local tags="$1"
  local max_version=0

  while IFS= read -r tag; do
    # Pattern: ^v([0-9]+)$ matches only simple vN tags (v1, v2, etc.)
    # This intentionally excludes semver tags like v1.2.3 for sequential versioning
    if [[ "$tag" =~ ^v([0-9]+)$ ]]; then
      local version="${BASH_REMATCH[1]}"
      if (( version > max_version )); then
        max_version="$version"
      fi
    fi
  done <<< "$tags"

  echo "$max_version"
}

# Gets the latest release tag from the repository
#
# Output:
#   The latest tag in vN format (e.g., "v5"), or "v0" if no matching tags exist
function git::latest_tag() {
  local all_tags
  all_tags=$(git tag -l 2>/dev/null)

  local max_version
  max_version=$(git::extract_max_version_number "$all_tags")

  echo "v$max_version"
}

# Checks if the current branch is up to date with origin and pulls if behind
#
# Prompts user for confirmation before pulling updates
function git::check_current_branch_and_pull() {
  git::fetch_origin
  # Check if the branch is behind
  local status_output=$(git status)

  if [[ "$status_output" == *"Your branch is behind"* ]]; then
    echo -e "${COLOR_RED}Your local branch is not up to date!${COLOR_RESET}"
    local question=$(echo -e "${COLOR_ORANGE}You have to have the latest changes.${COLOR_RESET} Apply git pull now?")
    io::confirm_or_exit "$question"
    echo -e "${COLOR_GREEN}Pulling updates...${COLOR_RESET}"
    git::pull_origin
  else
    echo -e "${COLOR_GREEN}Your branch is up to date!${COLOR_RESET}"
  fi

  git::status
}

# Force checks out a branch, handling post-checkout hooks safely
#
# This function temporarily disables post-checkout hooks during checkout to prevent
# interference with the release process, then restores them afterward.
#
# Arguments:
#   $1 - branch: The branch to checkout (with or without 'origin/' prefix)
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

  # Ensure upstream is configured (avoid "did not specify a branch" error)
  git branch --set-upstream-to=origin/"$branch_name" "$branch_name" >/dev/null 2>&1 || true

  git::pull_origin "$branch_name"

  [ -f .git/hooks/post-checkout.bak ] && mv .git/hooks/post-checkout.bak .git/hooks/post-checkout
  git config advice.detachedHead true
}

# Merges the target branch back to the develop branch
#
# This ensures hotfixes applied to the target branch are included in the develop branch.
#
# Arguments:
#   $1 - develop: The development branch name (e.g., "main")
#   $2 - target: The target/production branch name (e.g., "prod")
function git::update_develop() {
  local develop=$1
  local target=$2

  echo -e "Merging ${COLOR_ORANGE}$target${COLOR_RESET} back to" \
    "${COLOR_ORANGE}$develop${COLOR_RESET} (increase the release contains hotfixes" \
    "that are not in ${COLOR_ORANGE}$develop${COLOR_RESET})"

  git::force_checkout "$develop"
  git::merge_source_to_target "$target" "$develop"
}

# Merges the source branch into the target branch and pushes to origin
#
# Arguments:
#   $1 - source: The source branch to merge from
#   $2 - target: The target branch to merge into
#
# Returns:
#   Exits with 1 if merge fails, continues if successful
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

  if ! git push origin "$target" --no-verify; then
    echo -e "${COLOR_RED}Push failed for $target. Please check your network connection and permissions.${COLOR_RESET}"
    exit 1
  fi
}
