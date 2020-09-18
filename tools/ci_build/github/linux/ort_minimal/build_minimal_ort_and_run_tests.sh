#!/bin/bash

# This script will build a ORT minimal using
# 1. The included ops config file generated by build_full_ort_and_create_ort_files.sh,
# 2. The included models copied from <repo root>/onnxruntime/test/testdata/
# The build will run the unit tests for the minimal build
# Extra E2E test cases (converted by build_full_ort_and_create_ort_files.sh) will be run by onnx_test_runner

set -e

# Clear the previous build
rm -rf /build/Debug

# We need copy the related test files to a separated folder since the --include_ops_by_model will search the testdata folder recursively
# and include many unnecessary ops, minimal build UT currently uses .ort format models converted from the models we copied below,
# which will be used as the input of --include_ops_by_model to have ops to be included for the minimal build UT.
mkdir -p /home/onnxruntimedev/.test_data/models_to_exclude
cp /onnxruntime_src/onnxruntime/test/testdata/ort_github_issue_4031.onnx /home/onnxruntimedev/.test_data/models_to_exclude

# Build a minimal build with included ops and models
# then run ORT minimal UTs
/opt/python/cp37-cp37m/bin/python3 /onnxruntime_src/tools/ci_build/build.py \
    --build_dir /build --cmake_generator Ninja \
    --config Debug \
    --skip_submodule_sync \
    --build_shared_lib \
    --parallel \
    --minimal_build \
    --disable_ml_ops \
    --include_ops_by_model /home/onnxruntimedev/.test_data/models_to_exclude/ \
    --include_ops_by_config /home/onnxruntimedev/.test_data/ort_minimal_e2e_test_data/required_operators.config

# Run the e2e test cases
/build/Debug/onnx_test_runner /home/onnxruntimedev/.test_data/ort_minimal_e2e_test_data

# Clear the build
rm -rf /build/Debug
