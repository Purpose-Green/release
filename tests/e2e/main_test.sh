#!/bin/bash

function set_up() {
  source "$(current_dir)/../../src/main.sh"
}

function test_main_without_args() {
  assert_match_snapshot "$(main::action)"
}

function test_main_with_args() {
  assert_match_snapshot "$(main::action arg1 --option="value2")"
}
