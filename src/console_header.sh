#!/bin/bash
set -o allexport

function console_header::print_version() {
  printf "%s\n" "$RELEASE_VERSION"
}

function console_header::print_help() {
  cat <<EOL
Usage: release [arguments] [options]

Arguments:
  source-branch        The branch name to deploy.
  target-branch        The target branch to deploy to (optional, default: prod).
  development-branch   The development branch (optional, default: main).

Options:
  --debug              Enable debug mode (set -x).
  --dry-run            Simulate the deployment process without making any changes.
  --force              Ignore that your current local branch has ahead commits.
  --help               Display this help text.
  -v, --version         Display current version.
  -s, --source         Specify the source branch.
  -t, --target         Specify the target branch.
  -d, --development    Specify the development branch.

Examples:
  deploy main
  deploy main --dry-run
  deploy fix/... --force
  deploy fix/... --dry-run --force
EOL
}
