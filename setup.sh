#!/bin/bash -e

msg() {
  echo " >>> $1"
}

CWD=$(pwd)
umask 022

set --

echo "Creating rootfs dir..."

mkdir -vp $CWD/rootfs

mkdir -vp $CWD/rootfs/tools

cd $CWD/rootfs

mkdir -p ./{boot,dev,etc,mnt/root,proc,root,sys,tmp,usr/{bin,lib,sbin,share,include},run}

ln -s usr/bin bin

ln -s usr/sbin sbin
    
ln -s usr/lib lib

msg "Done setting up..."
