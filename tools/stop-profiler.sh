#!/bin/bash
# Starts the spark profiler on the server.

# Navigate to server root
cd "$(dirname "$0")/.."

# Read server options
. ./env.sh

# Make sure screen is active
if ! sudo -u $RUNAS screen -list | grep -q $SCREEN; then
  echo "Unable to stop Spark profiler as there is no screen $SCREEN running."
  exit 0
fi

echo "Stopping Spark profiler..."
./stuff.sh 'spark profiler stop'
echo "Spark profiler stopped.  Waiting for results..."
sleep 5s

URL="$(awk '/https:\/\/spark\.lucko\.me\/\S+/ {lines[i++]=$0} END{print lines[i-1]}' logs/latest.log | grep -oP 'https://spark\.lucko\.me/\S+')"

if [[! -z $URL]]; then
    echo "Got profiler resutls URL $URL"
    xdg-open $URL
else
    echo "Unable to determine Spark profiler results URL!"
fi

