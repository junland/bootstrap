#!/bin/bash -e

msg() {
  echo " >>> $1"
}

run_stage() {
    stage_target=$1

    export stage_target

    stage_name=$(echo ${stage_target} | sed 's/\//\-/g')
    
    if ! test -f $STRAP_CWD/$stage_target; then
      msg "Stage script does not exist: $stage_target"
      exit 1
    fi

    if test -f $STRAP_CWD/logs/$stage_name.done; then
      msg "Stage $stage_name has already been completed, skipping..."
      return
    fi

    chmod +x $STRAP_CWD/$stage_target

    . $STRAP_CWD/bootstrap.env

    msg "Running stage: $stage_name ($stage_target)"

    set -e

    . $STRAP_CWD/$stage_target

    if [ "$?" -ne "0" ]; then
       msg "Something went wrong with $stage_name, check the last few lines of logs to see the error."
       exit 1
    fi

    msg "Done with stage: $stage_name ($stage_target)"
    
    touch $STRAP_CWD/logs/$stage_name.done
}

mount_chroot() {
  msg "Creating file system directories..."
  
  mkdir -pv "$STRAP_ROOTFS"/{dev,proc,sys,run}

  msg "Mounting chroot..."
  
  mount -v --bind /dev "$STRAP_ROOTFS"/dev
  mount -vt devpts devpts "$STRAP_ROOTFS"/dev/pts -o gid=5,mode=620
  mount -vt proc proc "$STRAP_ROOTFS"/proc
  mount -vt sysfs sysfs "$STRAP_ROOTFS"/sys
  mount -vt tmpfs tmpfs "$STRAP_ROOTFS"/run

  msg "Done mounting chroot."
}

umount_chroot() {
  msg "Unmounting chroot..."

  umount -v "$STRAP_ROOTFS"/dev/pts
  umount -v "$STRAP_ROOTFS"/dev
  umount -v "$STRAP_ROOTFS"/run
  umount -v "$STRAP_ROOTFS"/proc
  umount -v "$STRAP_ROOTFS"/sys

  msg "Done unmounting chroot."
}

proot_run_cmd_tools() {
  for shell in "sh" "ash" "bash"; do
    msg "Searching for shell: $shell"
    if [ -f "$STRAP_ROOTFS"/bin/$shell ] || [ -L "$STRAP_ROOTFS"/bin/$shell ]; then
      msg "Selected $shell as rootfs shell..."
      export ROOTFS_SHELL=/bin/$shell
      break
    fi
  done

  ROOTFS_DIR_ARCH=$(echo "$1" | cut -d "-" -f1)
  CHROOT_CMD=$2

  if [ ! -f "/usr/bin/qemu-$(echo "$1" | cut -d "-" -f1)-static" ]; then
    msg "qemu static binary for $1 does not exist."
    exit 1
  fi

  mount_chroot

  msg "Executing '$CHROOT_CMD' command..."

  proot --cwd=/ -r "$STRAP_ROOTFS" -q qemu-"$ROOTFS_DIR_ARCH"-static /usr/bin/env -i \
        HOME=/ TERM="$TERM" \
        LC_ALL=POSIX \
        PS1='(chroot)$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin \
        $ROOTFS_SHELL -c "$CHROOT_CMD ; echo $? > /.exit-code.out"

  umount_chroot

  SIG_NUM=$(cat $STRAP_ROOTFS/.exit-code.out)

  msg "Here is the exit code..."

  cat $STRAP_ROOTFS/.exit-code.out

  if [ $SIG_NUM != "0" ]; then
     msg "Something went wrong with executing proot_run_cmd_tools..."
     exit "$SIG_NUM"
  fi

  return
}

export -f run_stage
export -f msg
export -f umount_chroot
export -f mount_chroot
export -f proot_run_cmd_tools

msg "Functions loaded..."
