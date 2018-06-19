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

if [[ $NODE_NAME = *"aix61"* ]]; then
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
elif [[ $NODE_NAME = *"centos7-arm64"* ]] ||
  [[ $NODE_NAME = *"docker-armv7"* ]] ||
  [[ $NODE_NAME = *"ubuntu1604-arm64"* ]]; then
  MAKE_JOB_COUNT=2
elif [[ $NODE_NAME = *"aix61"* ]]; then
  MAKE_JOB_COUNT=5
elif getconf _NPROCESSORS_ONLN; then
  MAKE_JOB_COUNT=$(getconf _NPROCESSORS_ONLN)
else
  MAKE_JOB_COUNT=$(getconf NPROCESSORS_ONLN)
fi

if ! [ -z ${JOBS+x} ]; then
  MAKE_JOB_COUNT=$JOBS
fi

MAKE_ARGS="-j $MAKE_JOB_COUNT"

if [[ $NODE_NAME != *"aix61"* ]] && [ $(make -v | grep 'GNU Make 4' -c) -ne 0 ]; then
  MAKE_ARGS="$MAKE_ARGS --output-sync=target"
fi

if [[ $NODE_NAME = *"freebsd"* ]] ||
  [[ $NODE_NAME = *"aix61-ppc"* ]]; then
  MAKE=gmake
else
  MAKE=make
fi

if [[ $NODE_NAME = *"ubuntu1404-ppc"* ]] ||
  [[ $NODE_NAME = *"aix61-ppc"* ]]; then
  CONFIG_FLAGS="--dest-cpu=ppc64"
else
  CONFIG_FLAGS=""
fi

if test $nodes = "centos6-64-gcc48"; then
  . /opt/rh/devtoolset-2/enable
elif [[ "$nodes" =~ centos[67]-(arm)?64-gcc6 ]]; then
  . /opt/rh/devtoolset-6/enable
fi

exec_cmd=" \
  NODE_TEST_DIR=${HOME}/node-tmp NODE_COMMON_PORT=15000 PYTHON=python \
  FLAKY_TESTS=$FLAKY_TESTS_MODE CONFIG_FLAGS=$CONFIG_FLAGS V=1 \
  $MAKE run-ci $MAKE_ARGS \
"

if [[ "$NODE_LABELS" =~ docker-armv7 ]]; then
  echo "Checking node label: $nodes"
  case $nodes in
    debian7-docker-armv7) debian=wheezy;;
    debian8-docker-armv7) debian=jessie;;
    debian9-docker-armv7) debian=stretch;;
    *) echo Error: Unsupported label $nodes; exit 1
  esac

  echo "$exec_cmd" > node-ci-exec
  sudo docker-node-exec.sh -v $debian
else
  $exec_cmd
fi

. ./build/jenkins/scripts/node-test-commit-diagnostics.sh after
