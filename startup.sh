#!/bin/bash

if ! lspci | grep NVIDIA; then
    echo "No GPU found. Not initializing"
    exit 0
fi

# Load kernel drivers
/usr/sbin/modprobe ipmi_devintf  # Is a dependency for the nvidia driver
/usr/sbin/insmod /opt/nvidia/modules/nvidia.ko
/usr/sbin/insmod /opt/nvidia/modules/nvidia-uvm.ko

# Create device files  (inspired by https://gist.github.com/tleyden/74f593a0beea300de08c)
COUNT=$(lspci | grep "VGA compatible controller: NVIDIA" | wc -l)

for i in $(seq 1 $COUNT); do
    rm -f /dev/nvidia$i
    mknod -m 666 /dev/nvidia$i c 195 $i
done

rm -f /dev/nvidiactl
mknod -m 666 /dev/nvidiactl c 195 255

if DEVICE=$(grep nvidia-uvm /proc/devices); then
    DEVICE_NUMBER=$( echo $DEVICE | cut -f 1 -d" ")
    rm -f /dev/nvidia-uvm
    mknod -m 666 /dev/nvidia-uvm c $DEVICE_NUMBER 0
fi