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

set --

echo "Creating rootfs dir..."

mkdir -vp $CWD/rootfs

mkdir -vp $CWD/rootfs/tools

cd $CWD/rootfs

mkdir -p ./{boot,dev,etc,mnt/root,proc,root,sys,tmp,usr/{bin,lib,sbin,share,include},run}

ln -s usr/bin bin

ln -s usr/sbin sbin
    
ln -s usr/lib lib

msg "Getting toolchain..."

wget -q $TOOLCHAIN_URL

msg "Unpacking toolchain..."

tar -xvf ./$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2 && rm ./$TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2.tar.bz2

msg "Relocate toolchain..."

cd $TOOLCHAIN_ARCH--glibc--bleeding-edge-2020.02-2

. ./relocate-sdk.sh

cd ..

msg "Done setting up toolchain..."
