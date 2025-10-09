#!/bin/bash
# Stuffs args into a screen

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
trap "popd >/dev/null" EXIT

# Configure the environment
. ./env.sh

log "Stuffing \"$@\" into $SCREEN stdin."

depends screen

sudo -u $RUNAS screen -S $SCREEN -X stuff "$*"`echo -ne '\015'`
