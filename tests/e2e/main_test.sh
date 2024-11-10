#!/bin/bash

function set_up() {
  SCRIPT="$(current_dir)/../../release"
}

function test_main_without_args() {
  spy gh
  spy git
  assert_match_snapshot "$($SCRIPT -h)"
}
