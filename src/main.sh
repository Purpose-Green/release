#!/bin/bash
set -euo pipefail

function main::action() {
  local args=("${@:-}")

  echo "Main Action"

  for arg in "${args[@]}"; do
    echo "$arg"
  done
}
