#!/bin/bash

msg() {
  echo " >>> $1"
}

run_stage() {
    stage_target=$1

    export stage_target
    
    if ! test -f $CWD/$stage_target; then
      msg "Stage script does not exist: $stage_target"
      exit 1
    fi

    if test -f $CWD/progress/$stage_target.done; then
      msg "Stage $stage_target has already been completed, skipping..."
      return
    fi

    chmod +x $CWD/$stage_target

    source $CWD/bootstrap.env

    msg "Running stage: $stage_target"

    set -e

    stg_name=$(echo ${stage_target} | sed 's/\//\-/g')

    . $CWD/bootstrap.env 2>&1 | tee $CWD/progress/$stg_name.log

    msg "Done with stage: $stage_target"

    touch $CWD/progress/$stg_name.done
}

export -f run_stage
export -f msg

msg "Functions loaded..."