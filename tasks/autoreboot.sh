#!/bin/bash
# When combined with a call to /sbin/shutdown -r +35, prepares the server for an
#   impending system reboot.

# Set directory to root
cd "$(dirname "$0")/.."

# Read environment variables
. ./env.sh

# if the SCREEN is not active we can skip the countdown part
if sudo -u $RUNAS screen -list | grep -q $SCREEN; then
    # 30 minute countdown.
    ./stuff.sh 'say The server will restart automatically in 30 minutes.'
    sleep 15m
    ./stuff.sh 'say The server will restart automatically in 15 minutes.'
    sleep 10m
    ./stuff.sh 'say The server will restart automatically in 5 minutes!'
    sleep 5m
    ./stuff.sh 'say The server will restart automatically in 1 minute!'
    sleep 30s
    ./stuff.sh 'say The server will restart automatically in 30 seconds!'
    ./stuff.sh 'save-all'
    sleep 15s
    ./stuff.sh 'say The server will restart automatically in 15 seconds!'
    sleep 10s
    ./stuff.sh 'say The server will restart automatically in 5 seconds...'
    sleep 1s
    ./stuff.sh 'say The server will restart automatically in 4 seconds...'
    sleep 1s
    ./stuff.sh 'say The server will restart automatically in 3 seconds...'
    sleep 1s
    ./stuff.sh 'say The server will restart automatically in 2 seconds...'
    sleep 1s
    ./stuff.sh 'say The server will restart automatically in 1 second!'
    sleep 1s
    ./stuff.sh 'say Goodbye!'
    ./stuff.sh "$KICK_CMD"
    ./stuff.sh 'stop'
    sleep 2m
fi

# Clear restart flag
rm -f .restart_flag > /dev/null

# Kill server process if it got stuck.
./kill.sh
