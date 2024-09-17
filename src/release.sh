#!/bin/bash
set -euo pipefail

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

function release::create_tag() {
  local new_tag=$1
  local changed_files=$2

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_YELLOW}--dry-run enabled. Skipping creating a tag ($new_tag)${COLOR_RESET}"
    return
  fi

  git tag -a "$new_tag" -m "Release $new_tag

Changes:
$changed_files"

  git push origin --tags --no-verify
}

# shellcheck disable=SC2155
function release::create_github_release() {
  if [ "$GH_CLI_INSTALLED" = false ]; then
    return
  fi

  local previous_tag=$1
  local new_tag=$2

  if [ "$previous_tag" = "v0" ]; then
    previous_tag="main"
  fi

  local commits=$(git log --oneline "$previous_tag".."$new_tag")
  local release_name=$(release::generate_release_name)
  local remote_url=$(git remote get-url origin)
  local repo_info=$(echo "$remote_url" | sed -E 's|git@github\.com:||; s|\.git$||')

  local changelog_url="https://github.com/$repo_info/compare/$previous_tag...$new_tag"
  local full_changelog="**Full Changelog**: $changelog_url"

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${COLOR_YELLOW}--dry-run enabled. Skipping creating a release ($release_name)${COLOR_RESET}"
    return
  fi

  gh release create "$new_tag" \
    --title "$release_name" \
    --notes "$(echo -e "$commits\n\n$full_changelog")"
}

# shellcheck disable=SC2155
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
