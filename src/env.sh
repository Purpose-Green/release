#!/bin/bash

# Using local with command substitution is acceptable for readability
# shellcheck disable=SC2155

# Load environment variables from .env file if it exists
# shellcheck source=/dev/null
[[ -f ".env" ]] && source .env set
set +o allexport

_DEFAULT_SOURCE_BRANCH="main"
_DEFAULT_TARGET_BRANCH="prod"
_DEFAULT_DEVELOPMENT_BRANCH="main"
_DEFAULT_SUCCESSFUL_TEXT=""
_DEFAULT_SLACK_CHANNEL_ID=""
_DEFAULT_SLACK_OAUTH_TOKEN=""

: "${RELEASE_SOURCE_BRANCH:=${SOURCE_BRANCH:=$_DEFAULT_SOURCE_BRANCH}}"
: "${RELEASE_TARGET_BRANCH:=${TARGET_BRANCH:=$_DEFAULT_TARGET_BRANCH}}"
: "${RELEASE_DEVELOPMENT_BRANCH:=${DEVELOPMENT_BRANCH:=$_DEFAULT_DEVELOPMENT_BRANCH}}"
: "${RELEASE_SUCCESSFUL_TEXT:=${SUCCESSFUL_TEXT:=$_DEFAULT_SUCCESSFUL_TEXT}}"
: "${RELEASE_SLACK_CHANNEL_ID:=${SLACK_CHANNEL_ID:=$_DEFAULT_SLACK_CHANNEL_ID}}"
: "${RELEASE_SLACK_OAUTH_TOKEN:=${SLACK_OAUTH_TOKEN:=$_DEFAULT_SLACK_OAUTH_TOKEN}}"

# Prompts for extra confirmation based on changed file paths
#
# Checks if any changed files match paths configured in RELEASE_EXTRA_CONFIRMATION,
# and prompts the user with a custom confirmation message.
#
# Arguments:
#   $1 - changed_files: Newline-separated list of changed file paths
#
# Environment:
#   RELEASE_EXTRA_CONFIRMATION: JSON map of paths to confirmation messages
#   Example: '{"src/critical": "Are you sure you want to modify critical files?"}'
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

# Executes extra commands based on changed file paths
#
# Checks if any changed files match paths configured in RELEASE_EXTRA_RUN_COMMANDS,
# and executes the associated commands. Each unique command is only executed once.
#
# Arguments:
#   $1 - changed_files: Newline-separated list of changed file paths
#
# Environment:
#   RELEASE_EXTRA_RUN_COMMANDS: JSON map of paths to shell commands
#   Example: '{"package.json": "npm install"}'
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
      if ! eval "$extra_command"; then
        echo -e "${COLOR_RED}Command failed: $extra_command${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Continuing with release...${COLOR_RESET}"
      fi
      executed_commands+=("$extra_command")
    fi
  done <<< "$changed_files"
}

# Displays the configured success message after release completion
#
# Environment:
#   RELEASE_SUCCESSFUL_TEXT: Text or URL to display on successful release
function env::render_successful_text() {
  if [[ -n "${RELEASE_SUCCESSFUL_TEXT:-}" ]]; then
    echo -e "$RELEASE_SUCCESSFUL_TEXT"
  fi
}
