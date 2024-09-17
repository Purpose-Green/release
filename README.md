# Deploy

This script automates deployment using your local Git. It:

- Selects the branch to deploy (e.g., `main`)
- Fetches the latest changes
- Compares commits with the target branch
- Prompts for confirmation
- Merges the branch
- Tags and creates a release
- Merges the branch back into the development branch

> Run this script locally; deployment happens on the server.

## How to use it?

```bash
./deploy --help
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
```

## Development

#### Source

- The entry point of the script is `./deploy`
- The source code is `src/`, split by different script files storing isolated functions.
- You can build the entire project and create a single executable script with `./build.sh`

#### Tests

The tests are inside `tests/`, using [bashunit](https://github.com/TypedDevs/bashunit/).

Use `install-dependencies.sh` to install bashunit inside your `lib/` folder
