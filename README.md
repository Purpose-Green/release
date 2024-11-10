# Release

This script automates creating a release using your local Git. It:

- Selects the branch to release (e.g., `main`)
- Fetches the latest changes
- Compares commits with the target branch
- Prompts for confirmation
- Merges the branch
- Tags and creates a release
- Merges the branch back into the development branch
- Share the changelog via Slack

> Run this script locally; deployment happens on the server after the release is created.

## How to use it?

```txt
./release --help
Usage: release [arguments] [options]

Arguments:
  source-branch        The branch name to release.

Options:
  --debug               Enable debug mode (set -x)
  -d, --dry-run         Simulate the release process without making any changes
  -f, --force           Ignore that your current local branch has ahead commits
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
```

## Env variables

> Note: you can (optionally) use `RELEASE_` as prefix for all env keys.
> Useful if you want to distinguish visually the origin of that env key-value.
> Eg: Using `SOURCE_BRANCH` will be equivalent to `RELEASE_SOURCE_BRANCH`.

### BRANCHES

#### SOURCE_BRANCH

The default source branch that you want to use for your releases.

> Default: `main`

#### TARGET_BRANCH

The default target branch that you want to use for your releases.

> Default: `prod`

#### DEVELOPMENT_BRANCH

If you have a different develop branch from the source branch, you can also define it here.

> Default: `main`

### SLACK

#### SLACK_CHANNEL_ID

The Slack channel ID where to publish the changelog message.

> Example: SLACK_CHANNEL_ID=#your-channel

#### SLACK_OAUTH_TOKEN

The Slack oauth token with the right of writing into your channel.

> Example: SLACK_CHANNEL_ID=xoxb-123-456-ABC789

### EXTRA

#### EXTRA_CONFIRMATION

Force asking for a new dialog when a filepath is found on such a directly (the key).
The value is the question forced to be asked. It must be [y/Y] to continue the release.

> Example: EXTRA_CONFIRMATION='{"migrations": "Migrations found! Remember to create a DB backup!"}'

#### EXTRA_RUN_COMMANDS

Run a command when a filepath is found on such a directory (the key).
The commands will be executed only once, even if multiple files are affected.
How? After running a command, this will be saved on memory to avoid running the same command twice.

> Example: EXTRA_RUN_COMMANDS='{"migrations": "api_call_to_create_DB_backup"}'

### SUCCESSFUL_TEXT

Display a text at the very end of the release.
Useful to have a link directly to the releases page to validate everything was good.

> Example: SUCCESSFUL_TEXT=https://github.com/Purpose-Green/release/releases

## Demo

### Using --dry-run

![](demo/using-dry-run.gif)

### Creating a new release

![](demo/creating-release.gif)

## Development

#### Env

Make sure you have .env ready to use.

```bash
cp .env.dist .env
```

#### Source

- The entry point of the script is `./release`
- The source code is `src/`, split by different script files storing isolated functions.
- You can build the entire project and create a single executable script with `./build.sh`

#### Tests

The tests are inside `tests/`, using [bashunit](https://github.com/TypedDevs/bashunit/).

Use `install-dependencies.sh` to install bashunit inside your `lib/` folder
