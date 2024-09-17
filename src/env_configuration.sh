#!/bin/bash

# shellcheck source=/dev/null
[[ -f ".env" ]] && source .env set
set +o allexport

TARGET_BRANCH=${TARGET_BRANCH:-"prod"}
DEVELOPMENT_BRANCH=${DEVELOPMENT_BRANCH:-"main"}

DEPLOY_SUCCESSFUL_TEXT=${DEPLOY_SUCCESSFUL_TEXT:-}
