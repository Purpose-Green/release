# Release

This is a guide to know the steps to create a new release.

1. Build the project `./build.sh --new major|minor|patch`
    1. Update the semantic version of the project
    1. Generate `bin/release` & `bin/checksum`
    1. Update [CHANGELOG.md](../CHANGELOG.md)
    1. Commit the latest changes `release: X.Y.Z`
1. Run `bin/release`
1. Attach `bin/release` and `bin/checksum` to the latest release
    1. https://github.com/Purpose-Green/deploy/releases
