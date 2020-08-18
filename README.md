# bootstrap

## What is this?

Bootstrap scripts to create a multi-architecture bootstrap Linux stages from scratch. This will hopefully be used to create a spiritual successor to CoreOS (Pre-RedHat buyout.), Clear Linux from Intel, and PhotonOS from VMware.

## How to get started

1. Install prerquesites

Ubuntu / Debian / DEB-based

```
rsync build-essential expect pkg-config libarchive-tools m4 gawk bc \ 
bison flex texinfo python3 perl libtool autoconf automake autopoint autoconf-archive \
mtools zlib1g-dev zlib1g xz-utils file wget gettext git
```

Fedora / OpenSUSE / CentOS / RPM-based

```
gcc gcc-g++ make bison flex rsync patch expect mtools python3 pigz libarchive \
bsdtar autoconf automake texinfo libtool zlib-devel xz-devel libzstd-devel libarchive-devel \
file-devel libcap-devel gettext-devel zlib-devel git wget
```

2. Clone Repo

```
git clone https://github.com/junland/bootstrap.git
```

3. Setup the enviroment with the architecture you want to build. (Only `x86_64` and `aarch64` supported at the moment.)

```
cd bootstrap
./strap-setup x86_64 
```

4. Build the toolchain.

```
./strap-toolchain x86_64
```

_Should produce a directory called `cross-toolchain`_

5. Cross compile the chroot.

```
./strap-chroot x86_64
```

_Should produce a directory called `rootfs`_
