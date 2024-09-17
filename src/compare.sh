#!/bin/bash
set -euo pipefail

# shellcheck disable=SC2005

function main::compare_branch_with_target() {
  local source=$1
  local target=$2

  echo -e "Comparing ${COLOR_ORANGE}$source${COLOR_RESET} with ${COLOR_ORANGE}$target${COLOR_RESET}"
  echo -e "${COLOR_BLUE}============================================${COLOR_RESET}"
  echo -e "Commits to include in the release (into ${COLOR_ORANGE}$target${COLOR_RESET}):"
  echo "$(git log --color --oneline origin/"$target".."$source")"
  echo -e "${COLOR_BLUE}============================================${COLOR_RESET}"
  echo -e "Changed files between '${COLOR_ORANGE}$target${COLOR_RESET}' and '${COLOR_ORANGE}$source${COLOR_RESET}':"
  compare::render_changed_files "$source" "$target"
  echo -e "${COLOR_PURPLE}============================================${COLOR_RESET}"
}

function compare::render_changed_files() {
  local source=$1
  local target=$2

  local added_files=()
  local modified_files=()
  local deleted_files=()

  # Collect files based on their status
  while read -r status file; do
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
  if [ "${#added_files[@]}" -gt 0 ]; then
    for file in "${added_files[@]}"; do
        echo -e "${COLOR_GREEN}+ $file${COLOR_RESET}"
    done
  fi

  # Modified (updated) files
  if [ "${#added_files[@]}" -gt 0 ]; then
    for file in "${modified_files[@]}"; do
        echo -e "${COLOR_YELLOW}~ $file${COLOR_RESET}"
    done
  fi


  # Deleted files
  if [ "${#added_files[@]}" -gt 0 ]; then
    for file in "${deleted_files[@]}"; do
        echo -e "${COLOR_RED}- $file${COLOR_RESET}"
    done
  fi
}
