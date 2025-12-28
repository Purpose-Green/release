#!/bin/bash
set -euo pipefail

# Generates the next version tag by incrementing the current version
#
# Arguments:
#   $1 - latest_tag: The current latest tag (e.g., "v5")
#   $2 - changed_files: List of changed files (not used but kept for API consistency)
#
# Output:
#   The next version tag (e.g., "v6")
function release::generate_new_tag() {
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

# Creates an annotated git tag and pushes it along with the branch to origin
#
# Arguments:
#   $1 - branch: The branch name (may include 'origin/' prefix)
#   $2 - new_tag: The version tag to create (e.g., "v5")
#   $3 - changed_files: List of changed files for the tag annotation
#
# Returns:
#   Exits with 1 if push fails
function release::create_tag() {
  local branch_name="${1#origin/}"  # Remove 'origin/' prefix if present
  local new_tag=$2
  local changed_files=$3

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping creating a tag ($new_tag)${COLOR_RESET}"
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping pushing changes ($branch_name)${COLOR_RESET}"
    return
  fi

  git tag -a "$new_tag" -m "Release $new_tag

Changes:
$changed_files"

  if ! git push origin "$new_tag" --no-verify; then
    echo -e "${COLOR_RED}Failed to push tag $new_tag." \
      "Please check your network connection and permissions.${COLOR_RESET}"
    exit 1
  fi

  if ! git push origin "$branch_name" --no-verify; then
    echo -e "${COLOR_RED}Failed to push branch $branch_name." \
      "Please check your network connection and permissions.${COLOR_RESET}"
    exit 1
  fi
}

# Creates a GitHub release with commit history and changelog link
#
# Requires the GitHub CLI (gh) to be installed.
#
# Arguments:
#   $1 - previous_tag: The previous release tag for changelog comparison
#   $2 - new_tag: The new version tag being released
#
# Note: If previous_tag is "v0" (first release), it uses "main" as the comparison base
#
# shellcheck disable=SC2155 - Using local with command substitution is acceptable for readability
function release::create_github_release() {
  if [[ "$GH_CLI_INSTALLED" == false ]]; then
    return
  fi

  local previous_tag=$1
  local new_tag=$2

  # v0 indicates this is the first release - use main branch as comparison base
  if [[ "$previous_tag" == "v0" ]]; then
    previous_tag="main"
  fi

  local release_name=$(release::generate_release_name)
  local remote_url=$(git remote get-url origin)
  # Handle both SSH and HTTPS URLs
  local repo_info=$(echo "$remote_url" | sed -E \
      -e 's|git@github\.com:|github.com/|' \
      -e 's|https://||' \
      -e 's|github.com/||' \
      -e 's|\.git$||')

  local changelog_url="https://github.com/$repo_info/compare/$previous_tag...$new_tag"
  local full_changelog="**Full Changelog**: $changelog_url"

  if [[ "$DRY_RUN" == true ]]; then
    new_tag=main
  fi

  local commits=$(git log --oneline "$previous_tag".."$new_tag")

  if [[ "$DRY_RUN" == false ]]; then
    gh release create "$new_tag" \
      --title "$release_name" \
      --notes "$(echo -e "$commits\n\n$full_changelog")"
  else
    echo -e "${COLOR_CYAN}--dry-run enabled. Skipping creating a release ($release_name)${COLOR_RESET}"
  fi

  slack::notify "$repo_info" "$release_name" "$changelog_url" "$commits" "$new_tag"
}

# Generates a date-based release name with sequential numbering
#
# Format: "YYYY-MM-DD #N" where N increments for each release on the same day
#
# Output:
#   A formatted release name (e.g., "2024-01-15 #1")
#
# shellcheck disable=SC2155 - Using local with command substitution is acceptable for readability
function release::generate_release_name() {
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
