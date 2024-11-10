#!/bin/bash

# shellcheck disable=SC2155
function io::confirm_or_exit() {
  local txt=$(echo -e "$1 [N/y]:")
  read -p "$txt " -r
  if [[ ! "${REPLY:0:1}" =~ ^[Yy]$ ]]; then
    echo "Input given not positive: '$REPLY' Exiting..."
    exit 1
  fi
}
