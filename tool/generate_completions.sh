#!/usr/bin/env sh

set -e

# We support completions for two forms of the command. First
# is `dart_dev`, which is the global version. Second is `ddev`
# which, if configured according to the README, will only work
# within a Dart project directory.

pub run completion:shell_completion_generator dart_dev ddev> lib/bash-completion.sh
