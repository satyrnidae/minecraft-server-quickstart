#!/bin/bash
# Queries the server if .watchdog_lock is present.  If the server does not
#   respond in a reasonable amount of time, tries to kill it and reboot.
# Uses mctools python package. Install with "pipx mctools" and ensure the
#   binaries are on your PATH.

cd "$(dirname "$0")/.."

# This will get overwritten by env
ENABLE_QUERY=0
MCLI=mcli

. ./env.sh

if [ $ENABLE_QUERY -eq 0 ]; then
    echo "Skipping watchdog check as ENABLE_QUERY is disabled."
    exit 0
fi

# Skip watchdog ping if the lock file is not present.
if [ ! -f .watchdog_lock ]; then
    echo "Skipping watchdog check as .watchdog_lock is not present."
    exit 0
fi

WATCHDOG_QUERY_FAILS=0
# Pull counter from watchdog_lock
. ./.watchdog_lock

# Query the Minecraft server
which $MCLI &>/dev/null || {
    echo 'Failed to query server; mctools was not found!\nPlease ensure mctools/mcli is on your PATH.'
    exit 127
}
$MCLI -t $QUERY_TIMEOUT localhost:$QUERY_PORT query &>/dev/null || {
    WATCHDOG_QUERY_FAILS=$(($WATCHDOG_QUERY_FAILS+1))
    echo "Failed to query server! Might be dead or stalled. (Failure #$WATCHDOG_QUERY_FAILS)"

    if [ $WATCHDOG_QUERY_FAILS -gt 2 ]; then
        echo 'Watchdog failed to query server three times! Killing server.'
        rm -f ./.watchdog_lock &>/dev/null
        ./kill.sh
        sleep 3s
        ./start.sh
    else
        echo "WATCHDOG_QUERY_FAILS=$WATCHDOG_QUERY_FAILS" >./.watchdog_lock
    fi
    exit 0
}
echo 'Server is fine.'
echo 'WATCHDOG_QUERY_FAILS=0' >./.watchdog_lock
