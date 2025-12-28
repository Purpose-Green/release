#!/bin/bash
set -o allexport

# Prints the current release tool version
function console_header::print_version() {
  printf "%s\n" "$RELEASE_VERSION"
}

# Prints usage information and available options
function console_header::print_help() {
  cat <<EOL
Usage: release [arguments] [options]

Arguments:
  source-branch        The branch name to release.

Options:
  --debug               Enable debug mode (set -x)
  -d, --dry-run         Simulate the release process without making any changes
  -f, --force           Ignore that your current local branch has ahead commits
  -e, --env             Load a custom env file overriding the .env environment variables
  -h, --help            Print Help (this message) and exit
  -v, --version         Print version information and exit
  --source branch       Specify the source branch
  --target branch       Specify the target branch (default: "prod")
  --develop branch      Specify the develop branch (default: source-branch)

Examples:
  release main
  release main --dry-run
  release fix/... --force
  release fix/... --dry-run --force
EOL
}
