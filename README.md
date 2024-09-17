# Deploy

This is a `deploy` script to help the creation of new releases.

In summary:
- it merges the source branch (`main` or `hotfix`) into target branch (`prod`)
- creates a new tag
- creates a new release
- updates the development branch (`main`) with latest target branch


## Features

- Testing library ready to use: [bashunit](https://github.com/TypedDevs/bashunit/)
  - `tests/`
- Source structure to place your functions scripts
  - `src/`
- Entry point ready to consume arguments and options
  - `./deploy`
- A building script to mount the whole project into one single executable script
  - `./build.sh`
- GitHub Actions to ensure every commit and PR are passing the acceptable
  - `.github/workflows/linter,static_analysis,tests`
- Optional pre-commit git hook to trigger tests, linter and static-analysis
  - `bin/pre-commit`
- A Makefile ready with basic commands
  - `Makefile`
