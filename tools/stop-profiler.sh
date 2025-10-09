#!/bin/bash
# Starts the spark profiler on the server.
# Dependencies:
#   - screen
#   - xdg-open
# Child scripts:
#   - stuff.sh
# Configuration variables:
#   - RUNAS:  The user with whom the screen would launch.
#   - SCREEN: The name of the screen that the server would run under.
# Exit codes:
#   - 66  (EX_NOINPUT):     The spark profiler URL wasn't in the log file.
#   - 69  (EX_UNAVAILABLE): The minecraft server does not appear to be running.
#   - 127 (EX_CMDNOTFOUND): Either xdg-open or screen were not executable and/or available on the PATH.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

depends screen
depends xdg-open

# Make sure screen is active
if ! sudo -u $RUNAS screen -list | grep -q $SCREEN; then
  fatal $EX_UNAVAILABLE "Unable to stop Spark profiler as there is no screen $SCREEN running."
fi

./stuff.sh 'spark profiler stop'
log "Spark profiler stopped.  Waiting for results..."
sleep 5s

url="$(awk '/https:\/\/spark\.lucko\.me\/\S+/ {lines[i++]=$0} END{print lines[i-1]}' logs/latest.log | grep -oP 'https://spark\.lucko\.me/\S+')"
if [[ ! -z $url ]]; then
    log "Got profiler resutls URL: $url"
    xdg-open $url
else
    fatal $EX_NOINPUT "Unable to determine Spark profiler results URL!"
fi
