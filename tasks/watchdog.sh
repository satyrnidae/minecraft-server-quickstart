#!/bin/bash
# Queries the server if .watchdog_lock is present.  If the server does not
#   respond in a reasonable amount of time, tries to kill it and reboot.
# Uses mctools python package. Install with "pipx mctools" and ensure the
#   binaries are on your PATH.

cd "$(dirname "$0")/.."

. ./env.sh

# Skip watchdog ping if the lock file is not present.
if [ ! -f .watchdog_lock ]; then
    echo "Skipping watchdog check as .watchdog_lock is not present."
    exit 0
fi

WD_FR=0
# Pull counter from watchdog_lock
. ./.watchdog_lock

# Query the Minecraft server
which mcli &>/dev/null || {
    echo 'Failed to query server; mctools was not found!\nPlease ensure mctools/mcli is on your PATH.'
    exit 127
}
mcli -t $QUERY_TIMEOUT localhost:$QUERY_PORT query &>/dev/null || {
    WD_FR=$(($WD_FR+1))
    echo "Failed to query server! Might be dead or stalled. (Failure #$WD_FR)"

    if [ $WD_FR -gt 2 ]; then
        echo 'Watchdog failed to query server three times! Killing server.'
        rm -f ./.watchdog_lock &>/dev/null
        ./kill.sh
        sleep 3s
        ./start.sh
    else
        echo "WD_FR=$WD_FR" >./.watchdog_lock
    fi
    exit 0
}
echo 'WD_FR=0' >./.watchdog_lock
