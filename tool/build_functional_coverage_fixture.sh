#!/usr/bin/env bash

cd test_fixtures/coverage/functional_test/
pub get
pub run dependency_validator -i browser,coverage
pub build
cd -
