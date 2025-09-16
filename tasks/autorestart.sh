#!/bin/bash
# Performs an automated restart of the server with a warning countdown, killing
# it if necessary.

# Set directory to root
cd "$(dirname "$0")/.."

# Read environment variables
. ./env.sh

# if the SCREEN is not active we can skip the countdown part
if sudo -u $RUNAS screen -list | grep -q $SCREEN; then
    # 30 minute countdown.
    ./tasks/countdown.sh $RESTART_TIMER "Server will restart"
    ./stuff.sh "$BCAST_CMD [\"\",{\"text\":\"Goodbye!\",\"color\":\"yellow\"}]"
    ./stuff.sh "$KICK_CMD \"The server is restarting! We'll be back in a bit!\""
    ./stuff.sh 'stop'
    # Give the server time to stop
    sleep 2m
fi

# Clear restart flag
rm -f .restart_flag > /dev/null

# Kill server process if it got stuck.
./kill.sh

# Restart the server process.
./start.sh
