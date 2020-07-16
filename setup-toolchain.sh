#!/bin/bash -e

CWD=$(pwd)
umask 022

if [ "$1" == "" ]; then
  echo " >>> Please specify a architecture to build."
  exit 1
fi

TOOLCHAIN_ARCH=$1
TOOLCHAIN_URL=https://toolchains.bootlin.com/downloads/releases/toolchains/$TOOLCHAIN_ARCH/tarballs/$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2

echo " >>> Creating rootfs dir..."

mkdir -vp $CWD/rootfs

echo " >>> Getting toolchain..."

wget $TOOLCHAIN_URL

echo " >>> Unpacking toolchain..."

tar -xvf ./$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2 && rm ./$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2

echo " >>> Relocate toolchain..."

. $CWD/$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2/relocate-sdk.sh

echo " >>> Done setting up toolchain..."
