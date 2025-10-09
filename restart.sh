#!/bin/bash
# Restarts the server by touching RESTART_FLAG and sending the stop command.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

depends screen
if ! sudo -u $RUNAS screen -list | grep -q $SCREEN; then
  fatal $EX_UNAVAILABLE "Unable to attach to nonexistent screen $SCREEN."
fi

# Sleep and warning subroutine
if [ $# -gt 0 ]; then
    ./tools/countdown $1 "Server will restart"
fi

log 'Marking server for restart and stopping it.'
touch .restart_flag

./stuff.sh save-all
sleep 1s
./stuff.sh stop
