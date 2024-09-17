#!/bin/bash

function set_up() {
  source "$(current_dir)/../../src/main.sh"
}

function test_main_action_without_args() {
  actual=$(main::action)

  assert_same "Main Action" "$actual"
}

function test_main_action_with_args() {
  actual=$(main::action arg1 --option="value2")

  assert_same "Main Action
arg1
--option=value2" "$actual"
}
