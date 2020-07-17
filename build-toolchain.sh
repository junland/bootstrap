#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2020, John Unland
# Copyright (c) 2019, mtezych

umask 022

PrepareSources() {
  local LINUX=linux-$LINUX_VER
  local BINUTILS=binutils-$BINUTILS_VER
  local GLIBC=glibc-$GLIBC_VER
  local GCC=gcc-$GCC_VER

  cd $BUILD_ROOT

  rm -rf *.tar.xz *-src *-build toolchain

  wget -q https://www.kernel.org/pub/linux/kernel/v$LINUX_VER_MAJ.x/$LINUX.tar.xz
  wget -q https://ftp.gnu.org/gnu/binutils/$BINUTILS.tar.xz
  wget -q https://ftp.gnu.org/gnu/glibc/$GLIBC.tar.xz
  wget -q https://ftp.gnu.org/gnu/gcc/$GCC/$GCC.tar.xz

  tar -xvf $LINUX.tar.xz
  tar -xvf $BINUTILS.tar.xz
  tar -xvf $GLIBC.tar.xz
  tar -xvf $GCC.tar.xz

  mv $LINUX linux-src
  mv $BINUTILS binutils-src
  mv $GLIBC glibc-src
  mv $GCC gcc-src

  cd gcc-src

  #sed -i '/lp64=/s/lib64/lib/' gcc/config/aarch64/t-aarch64-linux

  #sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64

  contrib/download_prerequisites
}

BuildBinutils() {
  mkdir -vp $BUILD_ROOT/binutils-build

  cd $BUILD_ROOT/binutils-build

  echo " >>> Build binutils"

  $BUILD_ROOT/binutils-src/configure \
    --prefix=$BUILD_ROOT/toolchain \
    --build=$HOST \
    --host=$HOST \
    --target=$TARGET \
    --with-sysroot=$BUILD_ROOT/toolchain/sysroot \
    $MULTILIB_OPTIONS

  make all -j${PJOBS}
  make install
}

BuildLinuxHeaders() {
  cd $BUILD_ROOT/linux-src

  make headers_install ARCH=$KARCH INSTALL_HDR_PATH=$BUILD_ROOT/toolchain/sysroot/usr
}

BuildFirstGCC() {
  mkdir -vp $BUILD_ROOT/gcc-first-build

  cd $BUILD_ROOT/gcc-first-build

  unset CC CXX AR AS RANLIB LD STRIP OBJCOPY OBJDUMP

  echo " >>> Build first GCC"

  $BUILD_ROOT/gcc-src/configure \
    --prefix=$BUILD_ROOT/toolchain \
    --build=$HOST \
    --host=$HOST \
    --target=$TARGET \
    --with-sysroot=$BUILD_ROOT/toolchain/sysroot \
    --enable-languages=c \
    --with-glibc-version=4.19 \
    --with-newlib \
    --without-headers \
    --disable-shared \
    --disable-threads \
    --disable-libssp \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libmpx \
    --disable-libquadmath \
    --disable-werror \
    $GCC_OPTIONS \
    $MULTILIB_OPTIONS

  make all -j${PJOBS}
  make install
}

BuildGlibc() {
  mkdir -vp $BUILD_ROOT/glibc-build

  cd $BUILD_ROOT/glibc-build

  echo " >>> Build first Glibc"

  export CC="$TARGET-gcc"
  export CXX="$TARGET-g++"
  export AR="$TARGET-ar"
  export AS="$TARGET-as"
  export RANLIB="$TARGET-ranlib"
  export LD="$TARGET-ld"
  export STRIP="$TARGET-strip"
  export OBJCOPY="$TARGET-objcopy"
  export OBJDUMP="$TARGET-objdump"

  $BUILD_ROOT/glibc-src/configure \
    --prefix=/usr \
    --build=$HOST \
    --host=$TARGET \
    --disable-profile \
    --disable-werror

  make all -j${PJOBS}
  make install install_root=$BUILD_ROOT/toolchain/sysroot

  unset CC CXX AR AS RANLIB LD STRIP OBJCOPY OBJDUMP
}

BuildGCC() {
  mkdir -vp $BUILD_ROOT/toolchain/sysroot/lib
  mkdir -vp $BUILD_ROOT/toolchain/sysroot/usr/lib

  mkdir -vp $BUILD_ROOT/gcc-build

  cd $BUILD_ROOT/gcc-build

   echo " >>> Build final GCC"

  unset CC CXX AR AS RANLIB LD STRIP OBJCOPY OBJDUMP

  $BUILD_ROOT/gcc-src/configure AR=ar LDFLAGS="-Wl,-rpath,$BUILD_ROOT/toolchain/lib " \
    --prefix=$BUILD_ROOT/toolchain \
    --build=$HOST \
    --host=$HOST \
    --target=$TARGET \
    --with-sysroot=$BUILD_ROOT/toolchain/sysroot \
    --enable-languages=c,c++ \
    --enable-shared \
    --enable-threads \
    --disable-werror \
    $GCC_OPTIONS \
    $MULTILIB_OPTIONS

  make all -j${PJOBS}
  make install
}

main() {
  BUILD_ROOT=$PWD
  PJOBS="${PJOBS:=4}"

  LINUX_VER=5.7
  LINUX_VER_MAJ=$(echo $LINUX_VER | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')
  BINUTILS_VER=2.31
  GLIBC_VER=2.31
  GCC_VER=10.1.0

  if [ "$1" == "" ]; then
    echo "Please specify a architecture to build."
    exit 1
  fi

  case "$1" in
    x86_64)
      TARGET=x86_64-bootstrap-linux-gnu
      KARCH=x86_64
      MULTILIB_OPTIONS="--disable-multilib"
      GCC_OPTIONS="--with-arch=x86-64 --with-tune=generic"
      export TARGET KARCH MULTILIB_OPTIONS GCC_OPTIONS
      ;;
    aarch64)
      TARGET=aarch64-bootstrap-linux-gnu
      KARCH=arm64
      MULTILIB_OPTIONS="--disable-multilib"
      GCC_OPTIONS="--with-abi=lp64 --with-arch=armv8-a --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
      export TARGET KARCH MULTILIB_OPTIONS GCC_OPTIONS
      ;;
    *)
      echo " >>> Architecture is not set or is not supported by this toolchain build tool!"
      exit 1
      ;;
  esac

  HOST=$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')

  PrepareSources

  export PATH=$BUILD_ROOT/toolchain/bin:$PATH

  echo " >>> Toolchain build started..."

  BuildBinutils
  BuildLinuxHeaders
  BuildFirstGCC
  BuildGlibc
  BuildGCC

  echo " >>> Toolchain build completed!"

  echo " >>> Cleaning up left overs..."

  rm -rf *.tar.xz *-src *-build

  echo " >>> Done!"

  exit 0
}

set -e +h

main "$@"
