#/bin/bash

rm -rf build
git clone https://github.com/nodejs/build.git

. ./build/jenkins/scripts/node-test-commit-pre.sh

if test $IGNORE_FLAKY_TESTS = "true"
then
  FLAKY_TESTS_MODE=dontcare
else
  FLAKY_TESTS_MODE=run
fi
echo FLAKY_TESTS_MODE=$FLAKY_TESTS_MODE

. ./build/jenkins/scripts/select-compiler.sh

NODE_TEST_DIR=${HOME}/node-tmp NODE_COMMON_PORT=15000 PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE make run-ci -j $(getconf _NPROCESSORS_ONLN)

. ./build/jenkins/scripts/node-test-commit-diagnostics.sh after
