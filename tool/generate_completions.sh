#!/usr/bin/env sh

set -e

pub run completion:shell_completion_generator ddev > tool/ddev-completion.sh
