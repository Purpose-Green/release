# Release

This is a guide to know the steps to create a new release.

1. Update the version in [DEPLOY_VERSION](../deploy)
1. Update the version in [CHANGELOG.md](../CHANGELOG.md)
1. Build the project `./build.sh bin` - This generates `bin/main` & `bin/checksum`
1. Create a [new release](https://github.com/Purpose-Green/deploy/releases/new) from GitHub
1. Attach `bin/main` and `bin/checksum` to the release
