# bash-skeleton

This is a skeleton to start building bash scripts within a powerful yet simple architecture in place.

## Features

- Testing library ready to use: [bashunit](https://github.com/TypedDevs/bashunit/)
  - `tests/`
- Source structure to place your functions scripts
  - `src/`
- Entry point ready to consume arguments and options
  - `./entry-point`
- A building script to mount the whole project into one single executable script
  - `./build.sh`
- GitHub Actions to ensure every commit and PR are passing the acceptable
  - `.github/workflows/linter,static_analysis,tests`
- Optional pre-commit git hook to trigger tests, linter and static-analysis
  - `bin/pre-commit`
- A Makefile ready with basic commands
  - `Makefile`

## Inspired by

This skeleton is the result of building other projects like:

- bashunit: https://github.com/TypedDevs/bashunit
- create-pr: https://github.com/Chemaclass/create-pr

## Contribute

Suggestions, ideas and PRs are more than welcome here!
Please, Check out our [CONTRIBUTING.md](.github/CONTRIBUTING.md) guidelines.
