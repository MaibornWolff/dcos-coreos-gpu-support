#!/bin/bash

cd $(dirname "${BASH_SOURCE[0]}")
WORKDIR=$(pwd)
NVIDIA_DRIVER_VERSION=$1
OUTPUT_DIR=$WORKDIR/nvidia

. /usr/share/coreos/release

# Prepare kernel sources
emerge-gitclone
emerge -gKv coreos-sources
cp /usr/lib64/modules/*/build/.config /usr/src/linux/
make -C /usr/src/linux modules_prepare

# Download and install nvidia drivers
mkdir -p /opt/nvidia
cd /opt/nvidia
wget http://us.download.nvidia.com/tesla/${NVIDIA_DRIVER_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run
chmod +x NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run
bash ./NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run -x
cd NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}
# Failure is ok because the installer can not load the driver kernel modules as we are not running with a coreos kernel prepared for it
IGNORE_MISSING_MODULE_SYMVERS=1 ./nvidia-installer -s -n --kernel-source-path=/usr/src/linux --no-check-for-alternate-installs --kernel-install-path=$WORKDIR --skip-depmod || echo "I don't care"

# Collect kernel modules, binaries and libraries
mkdir -p ${OUTPUT_DIR}/{lib,bin,modules}
cp kernel/*.ko ${OUTPUT_DIR}/modules
cp *.so.${NVIDIA_DRIVER_VERSION} ${OUTPUT_DIR}/lib
cp nvidia-smi nvidia-debugdump nvidia-persistenced ${OUTPUT_DIR}/bin
cp $WORKDIR/install_nvidia.sh $WORKDIR/nvidia.service $WORKDIR/startup.sh ${OUTPUT_DIR}/

cd ${OUTPUT_DIR}
tar cvfz nvidia.tar.gz bin lib modules install_nvidia.sh startup.sh nvidia.service
mv nvidia.tar.gz $WORKDIR/
