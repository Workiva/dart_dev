#!/usr/bin/env sh

set -e

# We only support completions when the command is run through
# the `ddev` alias detailed in the README.

echo "ERROR: This generation will no longer work; we had to remove the dependency on the completion package because it was incompatible with Dart 2.0"
pub run completion:shell_completion_generator ddev> lib/bash-completion.sh
