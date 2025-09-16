#!/bin/bash
# Stops the server by removing RESTART_FLAG and sending the stop command.
cd "$(dirname "$0")"

# Sleep and warning subroutine
if [ $# -gt 0 ]; then
    ./tasks/countdown $1 "Server will shut down"
fi
# Remove the restart flag if it is present.
rm .restart_flag &>/dev/null || true

./stuff.sh stop
sleep 2m
