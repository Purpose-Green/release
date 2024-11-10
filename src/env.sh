#!/bin/bash
# shellcheck disable=SC2155

# shellcheck source=/dev/null
[[ -f ".env" ]] && source .env set
set +o allexport

_DEFAULT_SOURCE_BRANCH="main"
_DEFAULT_TARGET_BRANCH="prod"
_DEFAULT_DEVELOPMENT_BRANCH="main"
_DEFAULT_SUCCESSFUL_TEXT=""

: "${RELEASE_SOURCE_BRANCH:=${SOURCE_BRANCH:=$_DEFAULT_SOURCE_BRANCH}}"
: "${RELEASE_TARGET_BRANCH:=${TARGET_BRANCH:=$_DEFAULT_TARGET_BRANCH}}"
: "${RELEASE_DEVELOPMENT_BRANCH:=${DEVELOPMENT_BRANCH:=$_DEFAULT_DEVELOPMENT_BRANCH}}"
: "${RELEASE_SUCCESSFUL_TEXT:=${SUCCESSFUL_TEXT:=$_DEFAULT_SUCCESSFUL_TEXT}}"

function env::run_extra_confirmation() {
  local changed_files=$1

  if [[ -z "${RELEASE_EXTRA_CONFIRMATION:-}" ]]; then
    return 0
  fi

  local confirmation_msg filepath
  while IFS= read -r filepath; do
    confirmation_msg=$(json::parse_text "$RELEASE_EXTRA_CONFIRMATION" "$filepath")
    if [[ -n "$confirmation_msg" ]]; then
      break
    fi
  done <<< "$changed_files"

  if [[ -n "$confirmation_msg" ]]; then
    echo -e "> ${COLOR_BLUE}Extra confirmation${COLOR_RESET} found for '$filepath'..."
    # shellcheck disable=SC2116
    local question="$(echo "${COLOR_RED}$confirmation_msg${COLOR_RESET}")"
    io::confirm_or_exit "$question"
  fi
}

function env::run_extra_commands() {
  local changed_files=$1

  # Return early if no extra run commands are defined
  if [[ -z "${RELEASE_EXTRA_RUN_COMMANDS:-}" ]]; then
    return 0
  fi

  local extra_command filepath
  local executed_commands=()

  # Iterate over each filepath and find the first applicable extra command
  while IFS= read -r filepath; do
    extra_command=$(json::parse_text "$RELEASE_EXTRA_RUN_COMMANDS" "$filepath")

    # Check if the command has already been executed
    local already_executed=false
    for cmd in "${executed_commands[@]:-}"; do
      if [[ "$cmd" == "$extra_command" ]]; then
        already_executed=true
        break
      fi
    done

    if [[ -n "$extra_command" && "$already_executed" == false ]]; then
      echo -e "> ${COLOR_BLUE}Extra command${COLOR_RESET} found for '$filepath'..."
      eval "$extra_command"
      executed_commands+=("$extra_command")
    fi
  done <<< "$changed_files"
}

function env::render_successful_text() {
  if [ -n "${RELEASE_SUCCESSFUL_TEXT:-}" ]; then
    echo -e "$RELEASE_SUCCESSFUL_TEXT"
  fi
}
