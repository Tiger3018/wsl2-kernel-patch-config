#!/usr/bin/env bash

sudo apt-get update && sudo apt-get install build-essential flex bison dwarves libssl-dev libelf-dev

patch kernel-5.10/Microsoft/config-wsl usb_cam-5.10.patch

mkdir -p build fakeroot/boot

pushd kernel-5.10
    make all KCONFIG_CONFIG=Microsoft/config-wsl O=../build V=1 -j$(getconf _NPROCESSORS_ONLN)
    # make dtbs_install INSTALL_PATH=../fakeroot V=1
    cp arch/x86/boot/bzImage ../fakeroot/boot/
    cp System.map ../fakeroot/boot/
    make modules_install INSTALL_MOD_PATH=../fakeroot V=1
    make headers_install INSTALL_HDR_PATH=../fakeroot/usr V=1
popd
shopt -s globstar
pushd build
    ls .tmp* .btf*
    rm -f .tmp* .btf*
popd
