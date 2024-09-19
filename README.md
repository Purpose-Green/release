# Release

This script automates creating a release using your local Git. It:

- Selects the branch to release (e.g., `main`)
- Fetches the latest changes
- Compares commits with the target branch
- Prompts for confirmation
- Merges the branch
- Tags and creates a release
- Merges the branch back into the development branch

> Run this script locally; deployment happens on the server after the release is created.

## How to use it?

```txt
./release --help
Usage: release [arguments] [options]

Arguments:
  source-branch        The branch name to release.
  target-branch        The target branch to release to (optional, default: prod).
  develop-branch       The develop branch (optional, default: main).

Options:
  --debug               Enable debug mode (set -x)
  -d, --dry-run         Simulate the release process without making any changes
  -f, --force           Ignore that your current local branch has ahead commits
  -h, --help            Print Help (this message) and exit
  -v, --version         Print version information and exit
  --source branch       Specify the source branch
  --target branch       Specify the target branch
  --develop branch      Specify the develop branch

Examples:
  release main
  release main --dry-run
  release fix/... --force
  release fix/... --dry-run --force
```

## Demo

### Using --dry-run

![](demo/using-dry-run.gif)

### Creating a new release

![](demo/creating-release.gif)

## Development

#### Source

- The entry point of the script is `./release`
- The source code is `src/`, split by different script files storing isolated functions.
- You can build the entire project and create a single executable script with `./build.sh`

#### Tests

The tests are inside `tests/`, using [bashunit](https://github.com/TypedDevs/bashunit/).

Use `install-dependencies.sh` to install bashunit inside your `lib/` folder
