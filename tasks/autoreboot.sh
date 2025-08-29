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
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"30 minutes","color":"yellow"},"."]'
    sleep 15m
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"15 minutes","color":"yellow"},"."]'
    sleep 10m
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"5 minutes","color":"yellow"},"."]'
    sleep 4m
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"1 minute","color":"yellow"},"!"]'
    sleep 30s
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"30 seconds","color":"yellow"},"!"]'
    ./stuff.sh 'save-all'
    sleep 15s
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"15 seconds","color":"yellow"},"!"]'
    sleep 10s
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"5 seconds","color":"red"},"..."]'
    sleep 1s
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"4 seconds","color":"red"},"..."]'
    sleep 1s
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"3 seconds","color":"red"},"..."]'
    sleep 1s
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"2 seconds","color":"red"},"..."]'
    sleep 1s
    ./stuff.sh 'title @a actionbar ["The server will restart in ",{"text":"1 second","color":"red"},"..."]'
    sleep 1s
    ./stuff.sh 'title @a title ["",{"text":"Goodbye!","color":"yellow"}]'
    ./stuff.sh "$KICK_CMD"
    ./stuff.sh 'stop'
    sleep 2m
fi

# Clear restart flag
rm -f .restart_flag > /dev/null

# Kill server process if it got stuck.
./kill.sh
