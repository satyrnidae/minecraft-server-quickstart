#!/bin/bash
# Starts the launcher script specified in $environment

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

banner "Started a new Minecraft server instance"

log "Launching as user $RUNAS in screen $SCREEN..."

sudo -u $RUNAS screen -dS $SCREEN -m "$LAUNCH_CMD" || {
    fatal $? "Failed to launch the server!"
}

log "Server launched in screen $SCREEN."

./attach.sh
