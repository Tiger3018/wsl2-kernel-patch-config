#!/usr/bin/env bash

sudo apt-get update && sudo apt-get install build-essential flex bison dwarves libssl-dev libelf-dev

patch kernel-5.10/Microsoft/config-wsl usb_cam-5.10.patch

mkdir -p build fakeroot

pushd kernel-5.10
    INSTALL_PATH=../fakeroot \
        make all KCONFIG_CONFIG=Microsoft/config-wsl O=../build -j$(getconf _NPROCESSORS_ONLN)
popd
shopt -s globstar
pushd build
    ls **/.tmp*
    rm -f **/.tmp*
popd
