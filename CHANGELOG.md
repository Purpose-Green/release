# Changelog

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
