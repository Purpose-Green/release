# Release

This is a guide to know the steps to create a new release.

1. Build the project `./build.sh bin` - This generates `bin/main` & `bin/checksum`
1. Make sure the `DEPLOY_VERSION` is up to date in [deploy](./deploy) entry point
    1. You can update this using `./build.sh bin --new major|minor|patch`
1. Update the version in [CHANGELOG.md](../CHANGELOG.md)
1. Run `bin/deploy`
1. Attach `bin/main` and `bin/checksum` to the latest release
    1. https://github.com/Purpose-Green/deploy/releases
