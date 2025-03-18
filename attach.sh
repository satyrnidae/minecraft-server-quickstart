#!/bin/bash
# Attaches to the screen session in which the server is running.

cd "$(dirname "$0")"

# Read server options
. ./env.sh

echo "Forcefully attaching to server on screen $SCREEN..."

sudo -u $RUNAS screen -dr $SCREEN
