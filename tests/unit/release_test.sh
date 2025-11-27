#!/bin/bash
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../src/release.sh"

function test_generate_new_tag_increments_version() {
  local result
  result=$(release::generate_new_tag "v5" "some files")
  assert_same "v6" "$result"
}

function test_generate_new_tag_from_v0() {
  local result
  result=$(release::generate_new_tag "v0" "some files")
  assert_same "v1" "$result"
}

function test_generate_new_tag_handles_large_numbers() {
  local result
  result=$(release::generate_new_tag "v789" "some files")
  assert_same "v790" "$result"
}

function test_generate_new_tag_handles_v100() {
  local result
  result=$(release::generate_new_tag "v100" "some files")
  assert_same "v101" "$result"
}
