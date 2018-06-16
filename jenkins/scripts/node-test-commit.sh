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

if getconf _NPROCESSORS_ONLN
then
  MAKE_JOB_COUNT=$(getconf _NPROCESSORS_ONLN)
else
  MAKE_JOB_COUNT=$(getconf NPROCESSORS_ONLN)
fi

if test $NODE_NAME = *"freebsd"*
then
  MAKE=gmake
else
  MAKE=make
fi

NODE_TEST_DIR=${HOME}/node-tmp NODE_COMMON_PORT=15000 PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE $MAKE run-ci -j $MAKE_JOB_COUNT

. ./build/jenkins/scripts/node-test-commit-diagnostics.sh after
