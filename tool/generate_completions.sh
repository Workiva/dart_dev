#!/usr/bin/env sh

set -e

pub run completion:shell_completion_generator ddev dart_dev > lib/bash-completion.sh
