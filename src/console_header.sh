#!/bin/bash
set -o allexport

function console_header::print_help() {
  cat <<EOL
Usage: deploy [options] [branch name] [target branch] [development branch]

Arguments:
  branch name          The branch name to deploy (SOURCE_BRANCH).
  target branch        The target branch to deploy to (TARGET_BRANCH, optional).
  development branch   The development branch (DEVELOPMENT_BRANCH, optional).

Options:
  --debug              Enable debug mode (set -x).
  --dry-run            Simulate the deployment process without making any changes.
  --force              Ignore that your current branch has ahead commits.
  -s, --source         Specify the source branch.
  -t, --target         Specify the target branch.
  -d, --development    Specify the development branch.

Examples:
  deploy main
  deploy main --dry-run
  deploy hotfix/... --force
  deploy feature/... --dry-run --force
  deploy main feature-branch --dry-run
EOL
}
