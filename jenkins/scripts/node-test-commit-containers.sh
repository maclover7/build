function fail_with_message {
  echo $1
  echo "1..1" > ${WORKSPACE}/test.tap
  echo "not ok 1 $1" >> ${WORKSPACE}/test.tap
  exit -1
}

FLAKY_TESTS_MODE=run
if test $IGNORE_FLAKY_TESTS = "true"; then
  FLAKY_TESTS_MODE=dontcare
fi
echo FLAKY_TESTS_MODE=$FLAKY_TESTS_MODE

if [ -z ${JOBS+x} ]; then
  JOBS=$(getconf _NPROCESSORS_ONLN)
fi

if [[ $JOB_NAME = *"ubuntu1604_sharedlibs_openssl110_x64"* ]]; then
  export LD_LIBRARY_PATH=${OPENSSL110DIR}/lib/
  export DYLD_LIBRARY_PATH=${OPENSSL110DIR}/lib/
  export PATH=${OPENSSL110DIR}/bin/:$PATH

  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --shared-openssl --shared-openssl-includes=${OPENSSL110DIR}/include/ --shared-openssl-libpath=${OPENSSL110DIR}/lib/" \
   make run-ci -j $JOBS --output-sync=target

  OPENSSL_VERSION="$(out/Release/node -pe process.versions | grep openssl)"
  echo "OpenSSL Version: $OPENSSL_VERSION"
  if [ X"$(echo $OPENSSL_VERSION | grep 1\.1\.0)" = X"" ]; then
    fail_with_message "Not built with OpenSSL 1.1.0, exiting"
  fi
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_fips20_x64"* ]]; then
  # First run of test-ci inside of run-ci either runs with FIPS on in 4.X or 5.X
  # or with FIPS off in 6.X or later (as the default was changed)

  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --openssl-fips=$FIPS20DIR" \
   make run-ci -j $JOBS --output-sync=target

  # validate using process.versions output that we actually built in FIPS capable
  # mode.  We expect to see "-fips" in the openssl version.  For example:
  # "openssl: '1.0.2d-fips"
  OPENSSL_VERSION="$(out/Release/node -pe process.versions | grep openssl)"
  echo "OpenSSL Version: $OPENSSL_VERSION"
  FIPS_CAPABLE="`echo "$OPENSSL_VERSION" | grep fips`"
  if [ X"$FIPS_CAPABLE" = X"" ]; then
    fail_with_message "Not built as FIPS capable, exiting"
  fi

  mv test.tap test-fips-base.tap

  NODE_VERSION="$(out/Release/node --version | awk -F "." '{print $1}' | sed 's/v//g')"

  # now run the tests with fips on if we are a version later than 5.X
  if [ "$NODE_VERSION" -gt "5" ]; then
    NODE_TEST_DIR=${HOME}/node-tmp PYTHON=python FLAKY_TESTS=$FLAKY_TESTS_MODE TEST_CI_ARGS="--node-args --enable-fips" make test-ci -j $JOBS
    mv test.tap test-fips-on.tap
  fi
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_debug_x64"* ]]; then
  # see https://github.com/nodejs/node/issues/17016
  sed -i 's/\[\$system==linux\]/[$system==linux]\ntest-error-reporting : PASS, FLAKY/g' test/parallel/parallel.status
  # see https://github.com/nodejs/node/issues/17017
  sed -i 's/\[\$system==linux\]/[$system==linux]\ntest-inspector-async-stack-traces-promise-then : PASS, FLAKY/g' test/sequential/sequential.status
  # see https://github.com/nodejs/node/issues/17018
  sed -i 's/\[\$system==linux\]/[$system==linux]\ntest-inspector-contexts : PASS, FLAKY/g' test/sequential/sequential.status

  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --debug" \
   make build-ci -j $JOBS --output-sync=target

  if ! [ -x out/Debug/node ]; then
    fail_with_message "No Debug executable"
  fi

  BUILD_TYPE="$(out/Debug/node -pe process.config.target_defaults.default_configuration)"
  echo "Build type: $BUILD_TYPE"
  if [ X"$BUILD_TYPE" != X"Debug" ]; then
    fail_with_message "Not built as Debug"
  fi

  python tools/test.py -j $JOBS -p tap --logfile test.tap \
    --mode=debug --flaky-tests=$FLAKY_TESTS_MODE \
    async-hooks default known_issues

  # Clean up any leftover processes, error if found.
  ps awwx | grep Debug/node | grep -v grep
  ps awwx | grep Debug/node | grep -v grep | awk '{print $$1}' | xargs -rl kill || true
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_openssl102_x64"* ]]; then
  export LD_LIBRARY_PATH=${OPENSSL102DIR}/lib/
  export DYLD_LIBRARY_PATH=${OPENSSL102DIR}/lib/
  export PATH=${OPENSSL102DIR}/bin/:$PATH

  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --shared-openssl --shared-openssl-includes=${OPENSSL102DIR}/include/ --shared-openssl-libpath=${OPENSSL102DIR}/lib/" \
   make run-ci -j $JOBS --output-sync=target

  OPENSSL_VERSION="$(out/Release/node -pe process.versions | grep openssl)"
  echo "OpenSSL Version: $OPENSSL_VERSION"
  if [ X"$(echo $OPENSSL_VERSION | grep 1\.0\.2)" = X"" ]; then
    fail_with_message "Not built with OpenSSL 1.0.2, exiting"
  fi
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_zlib_x64"* ]]; then
  export LD_LIBRARY_PATH=${ZLIB12DIR}/lib/
  export DYLD_LIBRARY_PATH=${ZLIB12DIR}/lib/

  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --shared-zlib --shared-zlib-includes=${ZLIB12DIR}/include/ --shared-zlib-libpath=${ZLIB12DIR}/lib/" \
   make run-ci -j $JOBS --output-sync=target

  ZLIB_VERSION="$(out/Release/node -pe process.versions | grep zlib)"
  echo "zlib Version: $ZLIB_VERSION"
  if [ X"$(echo $ZLIB_VERSION | grep 1\.2\.11)" = X"" ]; then
    fail_with_message "Not built with zlib 1.2.11, exiting"
  fi
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_openssl111_x64"* ]]; then
  export LD_LIBRARY_PATH=${OPENSSL111DIR}/lib/
  export DYLD_LIBRARY_PATH=${OPENSSL111DIR}/lib/
  export PATH=${OPENSSL111DIR}/bin/:$PATH

  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --shared-openssl --shared-openssl-includes=${OPENSSL111DIR}/include/ --shared-openssl-libpath=${OPENSSL111DIR}/lib/" \
   make run-ci -j $JOBS --output-sync=target

  OPENSSL_VERSION="$(out/Release/node -pe process.versions | grep openssl)"
  echo "OpenSSL Version: $OPENSSL_VERSION"
  if [ X"$(echo $OPENSSL_VERSION | grep 1\.1\.1)" = X"" ]; then
    fail_with_message "Not built with OpenSSL 1.1.1, exiting"
  fi
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_withoutintl_x64"* ]]; then
  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --without-intl" \
   make run-ci -j $JOBS --output-sync=target

  INTL_OBJECT="$(out/Release/node -pe 'typeof Intl')"
  echo "Intl object type: $INTL_OBJECT"
  if [ X"$INTL_OBJECT" != X"undefined" ]; then
    fail_with_message "Has an Intl object, exiting"
  fi
  PROCESS_VERSIONS_INTL="$(out/Release/node -pe process.versions.icu)"
  echo "process.versions.icu: $PROCESS_VERSIONS_INTL"
  if [ X"$PROCESS_VERSIONS_INTL" != X"undefined" ]; then
    fail_with_message "process.versions.icu not undefined, exiting"
  fi
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_withoutssl_x64"* ]]; then
  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --without-ssl" \
   make run-ci -j $JOBS --output-sync=target

  HAS_OPENSSL="$(out/Release/node -p 'Boolean(process.versions.openssl)')"
  echo "Has OpenSSL: $HAS_OPENSSL"
  if [ X"$HAS_OPENSSL" != X"false" ]; then
    fail_with_message "Has an OpenSSL, exiting"
  fi
  REQUIRE_CRYPTO="$(out/Release/node -p 'require("crypto")')"
  if test $? -eq 0; then
    fail_with_message 'require("crypto") did not fail, exiting'
  fi
elif [[ $JOB_NAME = *"ubuntu1604_sharedlibs_shared_x64"* ]]; then
  PYTHON=python \
   NODE_TEST_DIR=${HOME}/node-tmp \
   FLAKY_TESTS=$FLAKY_TESTS_MODE \
   CONFIG_FLAGS="$CONFIG_FLAGS --shared" \
   make run-ci -j $JOBS --output-sync=target
fi
