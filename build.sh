#!/bin/bash -e

msg() {
  echo " >>> $1"
}

CWD=$(pwd)
umask 022

pwd

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
    export GCC_FLAGS="--disable-multilib --with-arch=x86-64 --with-tune=generic --enable-cet=auto"
    ;;
  aarch64)
    export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"
    export XTARGET="aarch64-buildroot-linux-gnu"
    export KARCH="arm64"
    export GCC_FLAGS="--disable-multilib --with-arch=armv8-a --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
    ;;
  *)
    msg "Architecture is not set or is not supported by 'bootstrap' script"
esac

msg "Set host triplet to: $XHOST (HOST)"

msg "Set toolchain triplet to: $XTARGET (TARGET)"

msg "Set kernal arch to: $KARCH"

msg "Download Linux..."

wget -q https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.7.8.tar.xz

msg "Unpack Linux..."

tar -xf linux-5.7.8.tar.xz

msg "Build and Install Linux..."

cd linux-5.7.8

make mrproper

make headers ARCH="$KARCH"

find usr/include -name '.*' -delete && rm usr/include/Makefile

cp -rv usr/include $ROOTFS_DIR/usr

cp -rv usr/include $ROOTFS_DIR/tools

cd ..

msg "Download GCC..."

wget -q http://ftp.gnu.org/gnu/gcc/gcc-10.1.0/gcc-10.1.0.tar.xz

msg "Unpack GCC..."

tar -xf gcc-10.1.0.tar.xz

msg "Build and Install GCC..."

cd gcc-10.1.0

mkdir build

contrib/download_prerequisites

echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"\n' >> gcc/config/linux.h

echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h

cp -v gcc/Makefile.in{,.orig}

sed 's@\./fixinc\.sh@-c true@' gcc/Makefile.in.orig > gcc/Makefile.in

sed -i '/lp64=/s/lib64/lib/' gcc/config/aarch64/t-aarch64-linux

sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64

sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -O2/" {libiberty,gcc}/configure

cd build

../configure \
    --prefix=/tools \
    --libdir=/tools/lib64 \
    --build=${XHOST} \
    --host=${XTARGET} \
    --target=${XTARGET} \
    --with-local-prefix=/tools \
    --enable-languages=c,c++ \
    --with-system-zlib \
    --with-native-system-header-dir=/tools/include \
    --disable-libssp \
    $GCC_FLAGS \
    --enable-install-libiberty
    
make AS_FOR_TARGET="${XTARGET}-as" LD_FOR_TARGET="${XTARGET}-ld"

make install
