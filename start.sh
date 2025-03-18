#!/bin/bash
# Starts the launcher script specified in $environment
cd "$(dirname "$0")"

. ./env.sh

echo "Launching as user $RUNAS in screen $SCREEN..."

sudo -u $RUNAS screen -dS $SCREEN -m "$LAUNCH_CMD" || {
    echo "Failed to launch (Exit code: ${?})" >&2
    exit 1
}

echo "Server launched in screen $SCREEN."

sudo -u $RUNAS screen -r $SCREEN
