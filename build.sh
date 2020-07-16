#!/bin/bash -e

msg() {
  echo " >>> $1"
}

CWD=$(pwd)
umask 022

if [ "$1" == "" ]; then
  msg "Please specify a architecture to build."
  exit 1
fi

TOOLCHAIN_ARCH=$1

msg "Setting rootfs location..."

ROOTFS_DIR=$CWD/rootfs
export ROOTFS_DIR

msg "Setting toolchain PATH..."

PATH=$CWD/$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2/bin:$PATH
export PATH

msg "Toolchain path set: $PATH"

case "$TOOLCHAIN_ARCH" in
  x86_64 | x86-64-core-i7)
    export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"
    export XTARGET="x86_64-buildroot-linux-gnu"
    export KARCH="x86_64"
    ;;
  aarch64)
    export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"
    export XTARGET="aarch64-buildroot-linux-gnu"
    export KARCH="arm64"
    ;;
  *)
    msg "Architecture is not set or is not supported by 'bootstrap' script"
esac

msg "Set host triplet to: $XHOST (HOST)"

msg "Set toolchain triplet to: $XTARGET (TARGET)"

msg "Set kernal arch to: $KARCH"

msg "Download Linux..."

wget https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.7.8.tar.xz

msg "Unpack Linux..."

tar -xvf linux-5.7.8.tar.xz

msg "Install Linux..."

cd linux-5.7.8

make mrproper

make headers ARCH="$KARCH"

find usr/include -name '.*' -delete && rm usr/include/Makefile

cp -rv usr/include $ROOTFS_DIR/usr
