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

export -f run_stage
export -f msg

msg "Functions loaded..."