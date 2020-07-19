#!/bin/bash

msg() {
  echo " >>> $1"
}

run_stage() {
    stage_target=$1

    export stage_target
    
    if ! test -f $STRAP_CWD/$stage_target; then
      msg "Stage script does not exist: $stage_target"
      exit 1
    fi

    if test -f $STRAP_CWD/progress/$stage_target.done; then
      msg "Stage $stage_target has already been completed, skipping..."
      return
    fi

    chmod +x $STRAP_CWD/$stage_target

    source $STRAP_CWD/bootstrap.env

    msg "Running stage: $stage_name ($stage_target)"

    set -e

    stage_name=$(echo ${stage_target} | sed 's/\//\-/g')

    $STRAP_CWD/$stage_target 2>&1 | tee $STRAP_CWD/progress/$stage_name.log

    msg "Done with stage: $stage_name ($stage_target)"

    touch $STRAP_CWD/progress/$stage_name.done
}

export -f run_stage
export -f msg

msg "Functions loaded..."