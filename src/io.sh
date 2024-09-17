#!/bin/bash
set -euo pipefail

function io::confirm_or_exit() {
  # shellcheck disable=SC2155
  local txt=$(echo -e "$1 (Y/n):")
  read -p "$txt " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1
  fi
}
