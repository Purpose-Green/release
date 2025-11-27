#!/bin/bash
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../src/git.sh"

function test_extract_max_version_returns_highest_version() {
  local tags="v1
v2
v10
v5"
  assert_same "10" "$(git::extract_max_version_number "$tags")"
}

function test_extract_max_version_ignores_non_matching_tags() {
  local tags="feature-branch
v789
release-2024
v1.2.3
some-other-tag"
  assert_same "789" "$(git::extract_max_version_number "$tags")"
}

function test_extract_max_version_handles_mixed_tags_correctly() {
  local tags="v1
feature-x
v100
release-v2
v50"
  assert_same "100" "$(git::extract_max_version_number "$tags")"
}

function test_extract_max_version_returns_0_when_no_matching_tags() {
  local tags="feature-branch
release-2024
some-tag"
  assert_same "0" "$(git::extract_max_version_number "$tags")"
}

function test_extract_max_version_returns_0_for_empty_input() {
  assert_same "0" "$(git::extract_max_version_number "")"
}

function test_extract_max_version_handles_v0_correctly() {
  local tags="v0"
  assert_same "0" "$(git::extract_max_version_number "$tags")"
}

function test_extract_max_version_does_not_match_semver() {
  local tags="v1.2.3
v2.0.0
v10"
  assert_same "10" "$(git::extract_max_version_number "$tags")"
}

function test_extract_max_version_handles_single_v_tag() {
  local tags="v42"
  assert_same "42" "$(git::extract_max_version_number "$tags")"
}
