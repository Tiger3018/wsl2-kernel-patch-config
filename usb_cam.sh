#!/usr/bin/env sh

apt-get update && apt-get install build-essential flex bison dwarves libssl-dev libelf-dev

patch kernel-5.10/Microsoft/config-wsl usb_cam-5.10.patch

mkdir -p build

pushd kernel-5.10
make KCONFIG_CONFIG=Microsoft/config-wsl O=../build
popd
