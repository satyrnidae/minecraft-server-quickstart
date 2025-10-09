#!/bin/bash
# Opens the spark profiler URL.
# Dependencies:
#   - screen
#   - xdg-open
# Child scripts:
#   - stuff.sh
# Configuration variables:
#   - RUNAS:  The user with whom the screen would launch.
#   - SCREEN: The name of the screen that the server would run under.
# Exit codes:
#   - 69  (EX_UNAVAILABLE): The minecraft server does not appear to be running.
#   - 75  (EX_TEMPFAIL):    The spark profiler URL wasn't in the log file.
#   - 127 (EX_CMDNOTFOUND): Either xdg-open or screen were not executable and/or available on the PATH.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

depends xdg-open
depends screen

# Make sure screen is active
if ! sudo -u $RUNAS screen -list | grep -q $SCREEN; then
    fatal $EX_UNAVAILABLE "Unable to open Spark profiler as there is no screen $SCREEN running."
fi

log "Opening the spark profiler..."
./stuff.sh 'spark profiler open'
sleep 5s

url="$(awk '/https:\/\/spark\.lucko\.me\/\S+/ {lines[i++]=$0} END{print lines[i-1]}' logs/latest.log | grep -oP 'https://spark\.lucko\.me/\S+')"

if [[ ! -z $URL ]]; then
    log "Got Spark Profiler URL: $url"
    xdg-open $url
else
    fatal $EX_TEMPFAIL 'Unable to determine Spark profiler URL! Please try again.'
fi
