#!/bin/bash

## bashunit
curl -s https://bashunit.typeddevs.com/install.sh | bash -s lib 0.16.0

## create-pr
curl -L https://github.com/Chemaclass/create-pr/releases/download/0.6/create-pr -o lib/create-pr
chmod +x lib/create-pr
