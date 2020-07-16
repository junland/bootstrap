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
TOOLCHAIN_URL=https://toolchains.bootlin.com/downloads/releases/toolchains/$TOOLCHAIN_ARCH/tarballs/$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2

echo "Creating rootfs dir..."

mkdir -vp $CWD/rootfs

mkdir -vp $CWD/rootfs/tools

msg "Getting toolchain..."

wget $TOOLCHAIN_URL

msg "Unpacking toolchain..."

tar -xvf ./$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2 && rm ./$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2

msg "Relocate toolchain..."

. $CWD/$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2/relocate-sdk.sh

msg "Done setting up toolchain..."
