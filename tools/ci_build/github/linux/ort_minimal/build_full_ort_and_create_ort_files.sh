#!/bin/bash

# This script will run a full ORT build and use the python package built to generate ort format test files,
# and the exclude ops config file, which will be used in the build_minimal_ort_and_run_tests.sh
set -e -o -x

EXIT_CODE=1

# run a full build of ORT
# need the ort python package to generate the ORT format files
# choose not to run test since that will be covered by other CIs
/opt/python/cp37-cp37m/bin/python3 /onnxruntime_src/tools/ci_build/build.py \
    --build_dir /build --cmake_generator Ninja \
    --config Debug \
    --skip_submodule_sync \
    --parallel \
    --build_wheel \
    --skip_tests \
    --enable_pybind \
    --cmake_extra_defines PYTHON_INCLUDE_DIR=/opt/python/cp37-cp37m/include/python3.7m PYTHON_LIBRARY=/usr/lib64/librt.so

# install the ORT python wheel
/opt/python/cp37-cp37m/bin/python3  -m pip install -U /build/Debug/dist/*

# copy the test data to a separated folder
mkdir -p /home/onnxruntimedev/.test_data
cp -Rf /onnxruntime_src/onnxruntime/test/testdata/ort_minimal_e2e_test_data /home/onnxruntimedev/.test_data

# convert the onnx models the $HOME/.test_data to ort model
find /home/onnxruntimedev/.test_data -type f -name "*.onnx" -exec /opt/python/cp37-cp37m/bin/python3 \
    /onnxruntime_src/tools/python/convert_onnx_model_to_ort.py {} \;

# delete the original *.onnx file since we only need to *.optimized.onnx file for generating exclude ops config file
find /home/onnxruntimedev/.test_data -type f -name "*.onnx" -not -name "*.optimized.onnx" -delete

# generate a included ops config file
/opt/python/cp37-cp37m/bin/python3 /onnxruntime_src/tools/ci_build/exclude_unused_ops.py \
    --model_path /home/onnxruntimedev/.test_data \
    --write_combined_config_to /home/onnxruntimedev/.test_data/included_ops_config.txt

# delete all the .onnx files, because the minimal build will not run on onnx files
find /home/onnxruntimedev/.test_data -type f -name "*.onnx" -delete

# clear the build
rm -rf /build/Debug

EXIT_CODE=$?

set -e
exit $EXIT_CODE
