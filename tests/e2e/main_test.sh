#!/bin/bash

function set_up() {
  SCRIPT="$(current_dir)/../../release"
}

function test_main_without_args() {
  spy gh
  spy git
  assert_match_snapshot "$($SCRIPT -h)"
}

function test_main_input_given_not_positive() {
  skip "mocks are not ready yet to work on subshell..." && return
  spy gh
  spy read
  export REPLY=n

  mock io::confirm_or_exit echo confirming_io
  mock git::status echo "mocked git::status"
  mock git::fetch_origin echo "mocked git::fetch_origin"
  mock git::changed_files echo "mocked git::changed_files"
  mock git::latest_tag echo "mocked git::latest_tag"
  mock git::force_checkout echo "mocked git::force_checkout"
  mock git::update_develop echo "mocked git::update_develop"
  mock git::merge_source_to_target echo "mocked git::merge_source_to_target"

  assert_match_snapshot "$($SCRIPT --dry-run -f)"
}

function test_main_no_changed_files() {
  skip "mocks are not ready yet to work on subshell..." && return

  spy gh
  spy read
  export REPLY=y

  mock io::confirm_or_exit echo confirming_io
  mock git::status echo "mocked git::status"
  mock git::fetch_origin echo "mocked git::fetch_origin"
  mock git::changed_files echo "mocked git::changed_files"
  mock git::latest_tag echo "mocked git::latest_tag"
  mock git::force_checkout echo "mocked git::force_checkout"
  mock git::update_develop echo "mocked git::update_develop"
  mock git::merge_source_to_target echo "mocked git::merge_source_to_target"

  assert_match_snapshot "$($SCRIPT --dry-run -f)"
}

# idea: override bashunit mock - to write to /tmp/mocks.sh
function mock() {
  local command=$1
  shift

  if [[ $# -gt 0 ]]; then
    eval "function $command() { $*; }"
  else
    eval "function $command() { echo \"${CAT:-Mocked output}\"; }"
  fi

  export -f "${command?}"

  # shellcheck disable=SC2005
  echo "$(declare -f "$command")" >> /tmp/mocks.sh
  chmod +x /tmp/mocks.sh
  trap 'rm -f /tmp/mocks.sh' EXIT
}
