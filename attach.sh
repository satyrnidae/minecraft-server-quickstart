#!/bin/bash
# Attaches to the screen session in which the server is running.
# Dependencies:
#   - screen
# Child scripts:
#   - stuff.sh
# Configuration variables:
#   - RUNAS:    The user with whom the screen would launch.
#   - SCREEN:   The name of the screen that the server would run under.
# Exit codes:
#   - 69  (EX_UNAVAILABLE): The minecraft server does not appear to be running.
#   - 127 (EX_CMDNOTFOUND): screen was not executable and/or available on the PATH.

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

log "Forcefully attaching to $SCREEN."
sudo -u $RUNAS screen -dr $SCREEN
