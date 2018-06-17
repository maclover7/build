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

if [[ $NODE_NAME = *"aix"* ]]; then
  # Some of the tests require a file size limit that is greating that
  # string size limite (see https://github.com/nodejs/node/pull/16273#pullrequestreview-70282286)
  # Set the limit so the test can run
  # Disable for now as need more config to make it allowable
  #ulimit -f 4194304

  # LIBPATH must be set to /opt/freeware/lib for the git plugin to work, however
  # it must be unset for the build.  The ansible start script sets the libpath
  # so that when git runs its set, but we must unset it here otherwise it
  # causes the build to find the 32 bit stdc++ library instead of the 64 bit one
  # that we need when running binaries (like mksnapshot) since our target is 64 bit
  unset LIBPATH
  echo LIBPATH:$LIBPATH
fi

. ./build/jenkins/scripts/select-compiler.sh

if [[ $NODE_NAME = *"smartos"* ]]; then
  MAKE_JOB_COUNT=4
elif [[ $NODE_NAME = *"aix"* ]]; then
  MAKE_JOB_COUNT=5
elif getconf _NPROCESSORS_ONLN; then
  MAKE_JOB_COUNT=$(getconf _NPROCESSORS_ONLN)
else
  MAKE_JOB_COUNT=$(getconf NPROCESSORS_ONLN)
fi

if [[ $NODE_NAME = *"freebsd"* ]] || [[ $NODE_NAME = *"aix"* ]]; then
  MAKE=gmake
else
  MAKE=make
fi

if [[ $NODE_NAME = *"ppc"* ]]; then
  CONFIG_FLAGS="--dest-cpu=ppc64"
else
  CONFIG_FLAGS=""
fi

NODE_TEST_DIR=${HOME}/node-tmp NODE_COMMON_PORT=15000 PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE CONFIG_FLAGS=$CONFIG_FLAGS $MAKE run-ci -j $MAKE_JOB_COUNT

. ./build/jenkins/scripts/node-test-commit-diagnostics.sh after
