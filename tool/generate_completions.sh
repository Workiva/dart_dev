#!/usr/bin/env sh

set -e

# We only support completions when the command is run through
# the `ddev` alias detailed in the README.

pub run completion:shell_completion_generator ddev> lib/bash-completion.sh
