#/bin/bash

rm -rf build
git clone https://github.com/nodejs/build.git

. ./build/jenkins/scripts/node-test-commit-pre.sh

if [[ $IGNORE_FLAKY_TESTS = "true" ]]; then
  FLAKY_TESTS_MODE=dontcare
else
  FLAKY_TESTS_MODE=run
fi
echo FLAKY_TESTS_MODE=$FLAKY_TESTS_MODE

. ./build/jenkins/scripts/select-compiler.sh

if [[ $NODE_NAME = *"smartos"* ]]; then
  MAKE_JOB_COUNT=4
elif getconf _NPROCESSORS_ONLN; then
  MAKE_JOB_COUNT=$(getconf _NPROCESSORS_ONLN)
else
  MAKE_JOB_COUNT=$(getconf NPROCESSORS_ONLN)
fi

MAKE_ARGS="-j $MAKE_JOB_COUNT"

if [ $(make -v | grep 'GNU Make 4' -c) -ne 0 ]; then
  MAKE_ARGS="$MAKE_ARGS --output-sync=target"
fi

if [[ $NODE_NAME = *"freebsd"* ]]; then
  MAKE=gmake
else
  MAKE=make
fi

if [[ $NODE_NAME = *"ubuntu1404-ppc"* ]]; then
  CONFIG_FLAGS="--dest-cpu=ppc64"
else
  CONFIG_FLAGS=""
fi

if test $nodes = "centos6-64-gcc48"; then
  . /opt/rh/devtoolset-2/enable
elif [[ "$nodes" =~ centos[67]-(arm)?64-gcc6 ]]; then
  . /opt/rh/devtoolset-6/enable
fi

NODE_TEST_DIR=${HOME}/node-tmp NODE_COMMON_PORT=15000 PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE CONFIG_FLAGS=$CONFIG_FLAGS V=1 $MAKE run-ci $MAKE_ARGS

. ./build/jenkins/scripts/node-test-commit-diagnostics.sh after
