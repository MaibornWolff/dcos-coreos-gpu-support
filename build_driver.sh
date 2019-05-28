#!/bin/bash

. common.sh

docker run --rm -v $(pwd):/workdir bugroger/coreos-developer:${COREOS_VERSION} /workdir/_build_driver.sh ${NVIDIA_DRIVER_VERSION}


