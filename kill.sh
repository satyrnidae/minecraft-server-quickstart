#!/bin/bash
# Causes the running screen to exit via SIGTERM.
cd "$(dirname "$0")"

# Read launcher properties
. ./env.sh

echo "Sending SIGTERM to screen process and resuming..."
sudo -u $RUNAS kill -TERM $(sudo -u $RUNAS ps h --ppid $(sudo -u $RUNAS screen -ls | grep $SCREEN | cut -d. -f1) -o pid)
sudo -u $RUNAS screen -r $SCREEN
echo "Screen terminated."
