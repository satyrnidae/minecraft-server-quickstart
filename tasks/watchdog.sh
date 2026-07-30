#!/bin/bash
# Queries the server if .watchdog_lock is present.  If the server does not
#   respond in a reasonable amount of time, tries to kill it and reboot.
# Also restarts immediately, bypassing the failure counter, if the screen
#   session itself isn't running (i.e. the server isn't just stalled, it's
#   flat out down).
# Uses mctools python package. Install with "pipx mctools" and ensure the
#   binaries are on your PATH.
# Dependencies:
#   - mcli
# Child scripts:
#   - kill.sh
#   - start.sh
# Configuration variables:
#   - ENABLE_QUERY:    Set to 1 to enable this functionality
#   - MCLI:            Path to the MCLI executable.
#   - QUERY_TIMEOUT:   The time, in seconds, to wait for the query result. May need to be adjusted if the startup time for your server is very long.
#   - QUERY_PORT:      Set to the query_port of your server, available in server.properties
#   - MAX_QUERY_FAILS: The number of times that the query can fail before the server is killed and restarted.
# Exit codes:
#   - 66 (EX_NOINPUT): No .watchdog_lock file could be found.
#   - 78 (EX_CONFIG):  Query is disabled or MCLI could not be found.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

if [ $ENABLE_QUERY -eq 0 ]; then
    fatal $EX_CONFIG 'Skipping watchdog check as ENABLE_QUERY is disabled.'
fi

if ! command -v "$MCLI" >/dev/null 2>&1; then
    fatal $EX_CONFIG "Unable to execute $MCLI, ensure your configuration is correct or that the executable is on your path."
fi

# The screen session may be gone entirely (e.g. the process was killed and
#   run.sh never got the chance to clean up .watchdog_lock). In that case
#   the server isn't stalled, it's just not running, so restart it right
#   away instead of waiting on the query failure counter below.
if ! sudo -u $RUNAS screen -ls | grep -q $SCREEN; then
    error 'Watchdog found no running screen session! Restarting server.'i

    if [ -f .watchdog_lock ]; then
        warning 'Found .watchdog_lock file, but no screen session. Removing orphaned lock file.'
        rm -f ./.watchdog_lock >/dev/null
    fi
    ./start.sh
    exit $EX_OK
fi

if ! [ -f .watchdog_lock ]; then
    fatal $EX_NOINPUT 'Screen running. Skipping watchdog check as no .watchdog_lock file was found.'
fi

# Pull counter from watchdog_lock
WATCHDOG_QUERY_FAILS=0
. ./.watchdog_lock

# Query the Minecraft server
"$MCLI" -t $QUERY_TIMEOUT localhost:$QUERY_PORT query >/dev/null || {
    if [ -f .watchdog_lock ]; then
        WATCHDOG_QUERY_FAILS=$(($WATCHDOG_QUERY_FAILS+1))
        warning "Failed to query server! Might be dead or stalled. (Failure #$WATCHDOG_QUERY_FAILS)"

        if [ $WATCHDOG_QUERY_FAILS -ge $MAX_QUERY_FAILS ]; then
            error 'Watchdog failed to query server three times! Killing server.'
            rm -f ./.watchdog_lock >/dev/null
            ./kill.sh
            sleep 3s
            ./start.sh
        else
            echo "WATCHDOG_QUERY_FAILS=$WATCHDOG_QUERY_FAILS" >./.watchdog_lock
        fi
        exit $EX_OK
    else
        fatal $EX_NOINPUT '.watchdog_lock file was deleted or could not be found. Canceling query.'
    fi
}
log 'Server is fine.'
log 'WATCHDOG_QUERY_FAILS=0' >./.watchdog_lock
