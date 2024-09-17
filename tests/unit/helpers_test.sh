#!/bin/bash

function test_helper_current_dir() {
  assert_same "tests/unit" "$(current_dir)"
}

function test_helper_current_filename() {
  assert_same "helpers_test.sh" "$(current_filename)"
}
