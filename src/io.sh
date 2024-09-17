#!/bin/bash
set -euo pipefail

# shellcheck disable=SC2155
function io::confirm_or_exit() {
  local txt=$(echo -e "$1 (Y/n):")
  read -p "$txt " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1
  fi
}
