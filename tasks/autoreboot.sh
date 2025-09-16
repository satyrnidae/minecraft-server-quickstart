#!/bin/bash
# When combined with a call to /sbin/shutdown -r +35, prepares the server for an
#   impending system reboot.

# Set directory to root
cd "$(dirname "$0")/.."

# Read environment variables
. ./env.sh

# if the SCREEN is not active we can skip the countdown part
if sudo -u $RUNAS screen -list | grep -q $SCREEN; then
    # Configurable countdown.
    ./tasks/countdown.sh $RESTART_TIMER "Host will reboot"
    ./stuff.sh "$BCAST_CMD [\"\",{\"text\":\"Goodbye!\",\"color\":\"yellow\"}]"
    ./stuff.sh "$KICK_CMD \"The server host is rebooting! We'll be back in a while!\""
    ./stuff.sh 'stop'
    # Give the server time to stop.
    sleep 2m
fi

# Clear restart flag
rm -f .restart_flag > /dev/null

# Kill server process if it got stuck.
./kill.sh
