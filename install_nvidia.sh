#!/bin/bash



# Directories
WORKDIR=$(pwd)
BASE_DIR=/opt/nvidia
LIB_DIR=${BASE_DIR}/lib
MODULES_DIR=${BASE_DIR}/modules
BIN_DIR=${BASE_DIR}/bin

mkdir -p $LIB_DIR $MODULES_DIR $BIN_DIR

# Copy files to their target places
cp startup.sh /opt/nvidia/
chmod +x /opt/nvidia/startup.sh

if ! lspci | grep NVIDIA; then
    echo "No GPU found. Not installing"
    exit 0
fi

cp bin/* $BIN_DIR/
cp modules/* $MODULES_DIR/
cp lib/* $LIB_DIR/
cd $LIB_DIR
for lib in *.so.*; do
	ln -s $lib ${lib/.so.*/.so.1}
done

# Update ld cache
mkdir -p /etc/ld.so.conf.d/
echo $LIB_DIR > /etc/ld.so.conf.d/nvidia.conf
ldconfig
