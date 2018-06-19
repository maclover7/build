curl https://raw.githubusercontent.com/nodejs/build/master/jenkins/scripts/node-test-commit-pre.sh | bash -xe

if test $IGNORE_FLAKY_TESTS = "true"
then
  FLAKY_TESTS_MODE=dontcare
else
  FLAKY_TESTS_MODE=run
fi

echo FLAKY_TESTS_MODE=$FLAKY_TESTS_MODE

export JOBS=5

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

# CC must be defined as gcc, otherwise cares uses cc which does not exist.  This is possibly an omission on the cares port
# --dest-cpu=ppc64 is set as we want to build the 64 bit version
# -j 1 is currently used as we saw problems with "directory already exists" with a higher number, still needs to be investigated
#NODE_TEST_DIR=${HOME}/node-tmp PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE CONFIG_FLAGS="--dest-cpu=ppc64" CC=gcc gmake run-ci -j $(lsdev -C -c processor | wc -l)
#NODE_TEST_DIR=${HOME}/node-tmp PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE CONFIG_FLAGS="$CONFIG_FLAGS --dest-cpu=ppc64" CC=gcc gmake run-ci -j $JOBS

rm -rf build
git clone https://github.com/nodejs/build.git
. ./build/jenkins/scripts/select-compiler.sh

# CC must be defined as gcc, otherwise cares uses cc which does not exist.  This is possibly an omission on the cares port
# Currently CC is set by the compiler selection script above
# --dest-cpu=ppc64 is set as we want to build the 64 bit version
#NODE_TEST_DIR=${HOME}/node-tmp PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE CONFIG_FLAGS="--dest-cpu=ppc64" CC=gcc gmake run-ci -j $(lsdev -C -c processor | wc -l)
NODE_TEST_DIR=${HOME}/node-tmp PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE CONFIG_FLAGS="$CONFIG_FLAGS --dest-cpu=ppc64" gmake run-ci -j $JOBS

curl https://raw.githubusercontent.com/nodejs/build/master/jenkins/scripts/node-test-commit-diagnostics.sh | bash -ex -s after
