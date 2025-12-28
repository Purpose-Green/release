# Changelog

## [Unreleased]

### Added
- New `src/console.sh` with utility functions: `console::info`, `console::success`, `console::error`, `console::warn`, `main::is_dry_run`, `git::strip_origin_prefix`, `env::is_slack_configured`
- Comprehensive function documentation for all 28+ functions
- ShellCheck disable comment explanations throughout codebase
- Automated GitHub release workflow (`.github/workflows/release.yml`)

### Fixed
- Added error handling to all `git push` operations in `src/git.sh` and `src/release.sh`
- Added error handling around `eval` in `src/env.sh` for extra commands
- Fixed insecure temp file handling in `src/slack.sh` using `mktemp` with cleanup trap
- Replaced all `[` with `[[` for consistent modern Bash syntax

### Changed
- Documented magic values (v0 special case, regex patterns for version matching)
- Improved code consistency across all modules

## [0.8.5](https://github.com/Purpose-Green/release/compare/v18...v19) - 2025-11-27

- d1d6e1e Merge pull request #21 from Purpose-Green/fix/20-find-next-version
- bdcacd4 fix: filter tags by vNUMBER pattern to prevent version reset
- 67f8e05 ignore .claude/

## [0.8.4](https://github.com/Purpose-Green/release/compare/v17...v18) - 2025-08-26

- 88dd52f Merge pull request #19 from Purpose-Green/fix/git-pull
- 04a786e fix: linter
- ca9a75d chore: update install-dependencies.sh
- 3c92b68 refactor: remove duplicate branch_name local var
- ea1532e refactor: mv test/helpers to tests/bootstrap
- 46e2d6b fix: git pull
- 4f02e0b set bashunit:0.21.0 - mocks are fixed

## [0.8.3](https://github.com/Purpose-Green/release/compare/v16...v17) - 2025-05-20

- 25b4644 update license

## [0.8.2](https://github.com/Purpose-Green/release/compare/v15...v16) - 2024-12-17

- d1cd38f fix
- c3697a7 release: 0.8.1

## [0.8.1](https://github.com/Purpose-Green/release/compare/v14...v15) - 2024-12-17

- fix not pushing to prod

## [0.8.0](https://github.com/Purpose-Green/release/compare/v11...v12) - 2024-12-12

- cc236cb trigger CI
- f519545 chore: add colors to git::check_current_branch_and_pull
- 8ae322b refactor: move git::check_current_branch_and_pull
- a471a4a feat: add main::check_current_branch_and_pull
- 7437267 feat: use pull instead of fetch on main::action
- a26b090 fix: style increment_tag_version
- 0f8c591 fix: new_tag increment_tag_version on build.sh
- 84fc2c8 Merge pull request #14 from Purpose-Green/feat/git-pull
- d9ff96e fix: remove duplicated git push branch on create_tag()
- 0cfaf78 feat: git::pull_origin on force_checkout
- dd35ce6 chore: add git::pull_origin
- 684695f docs: update readme
- df76bdd chore: load dev/dumper.sh only if exists
- 915ac49 chore: add make install and test
- a12c341 chore: add make create-pr
- 5c0b546 chore: update dev/dumper.sh
- 84cb207 chore: color vars in render_steps()
- e6ed05f fix: push only new tag instead of all

## [0.7.0](https://github.com/Purpose-Green/release/compare/v10...v11) - 2024-12-11

- 0eec321 docs: add -e, --env to readme
- ae52593 feat: add -e|--env option
- 5a1761f chore: split .env from .env.tools

## [0.6.0](https://github.com/Purpose-Green/release/compare/v9...v10) - 2024-11-10

- 79f29f5 feat: add RELEASE_ prefix to SLACK env variables
- 80a0840 Merge pull request #9 from Purpose-Green/feat/improve-env-variables
- 52764b6 fix: shellcheck on main_test.sh
- c1a200b docs: update readme
- 28a8ecd chore: move git commands to its own file git.sh
- b333e3b chore: move env vars to env.sh
- 8098243 Merge pull request #8 from Purpose-Green/feat/extra-commands
- 45e451b chore: extract func render_successful_text
- 7ad654a chore: move run_extra functions to env namespace
- 44ba656 chore: removed dev/test files
- dfba52d chore: avoid running twice the same extra command
- 760ec62 test: add 2 files on src/dev for testing
- f157ea4 docs: add RELEASE_EXTRA_RUN_COMMANDS to readme
- 438f24a feat: add main::extra_run_commands
- 1ca4a3e chore: add function prefix to dev/dumper.sh
- 2f65fd0 feat: force user interaction on confirm_or_exit
- ce5ea87 docs: move Demo below Env variables on readme

## [0.5.0](https://github.com/Purpose-Green/release/compare/v8...v9) - 2024-11-06

- Use [bashdep](https://github.com/Chemaclass/bashdep) to install dependencies
- Add `RELEASE_EXTRA_CONFIRMATION` to force asking for a new dialog when a filepath is found on such a key.

## [0.4.1](https://github.com/Purpose-Green/release/compare/v7...v8) - 2024-09-30

- ec2e1e5 add release url to the release name in slack msg
- 87c38dc refactor: inline notes variable when creating gh release

## [0.4.0](https://github.com/Purpose-Green/release/compare/v6...v7) - 2024-09-28

- d6a1dbd feat: add slack integration using slack api chat.postMessage
- 975b90f add .env to ignore. Commit .env.dist instead
- e427e92 deps: use bashunit:beta
- f26aa8d fix: support http remote to build full changelog url

## [0.3.0](https://github.com/Purpose-Green/release/compare/v5...v6) - 2024-09-19

- 5952a9e fix: release::create_tag
- 8fe5394 refactor: improve force_checkout
- d4971d4 docs: improve print_help
- 31ef3c4 Merge pull request #5 from Purpose-Green/feat/4-rename-project-to-release
- 63bde34 deps: add lib/create-pr to install-deps script
- c25362b feat: rename deploy -> release

## [0.2.1](https://github.com/Purpose-Green/deploy/compare/origin/v4...v5) - 2024-09-18

- 83a348a fix: console_header::print_version
- 2a0f482 docs: update readme

## [0.2.0](https://github.com/Purpose-Green/deploy/compare/origin/v3...v4) - 2024-09-18

- 32d1c46 docs: update release notes
- b168c7f feat: update changelog after building a new version
- 1e917b5 refactor: use ENTRY_POINT in build
- b2d5bcb Merge pull request #3 from Purpose-Green/feat/1-add-version
- d5d334a update changelog
- c1ea686 refactor: use global DEPLOY_VERSION instead of src/version.txt
- d82fecd docs: update .env adding create-pr vars
- 7569830 docs: update release docs
- 5c1bfe5 refactor: remove local folder
- f9c3ac9 feat: add --new option on build.sh
- e524de9 refactor: move version inside src/version.txt
- c4de7bd feat: add new --version option

## [0.1](https://github.com/Purpose-Green/deploy/compare/main...v3) - 2024-09-17

Initial release. Check README for instructions about installation and how to use it.
