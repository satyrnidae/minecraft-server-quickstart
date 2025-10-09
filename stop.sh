#!/bin/bash
# Stops the server by removing RESTART_FLAG and sending the stop command.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

# Sleep and warning subroutine
if [ $# -gt 0 ]; then
    ./tools/countdown $1 "Server will shut down"
fi
# Remove the restart flag if it is present.
rm .restart_flag &>/dev/null || true

./stuff.sh stop
