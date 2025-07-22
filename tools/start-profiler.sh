#!/bin/bash
# Starts the spark profiler on the server.

# Navigate to server root
cd "$(dirname "$0")/.."

# Read server options
. ./env.sh

# Make sure screen is active
if ! sudo -u $RUNAS screen -list | grep -q $SCREEN; then
  echo "Unable to start Spark profiler as there is no screen $SCREEN running."
  exit 0
fi

echo "Starting Spark profiler..."
./stuff.sh 'spark profiler start'
echo "Spark profiler started.  You can monitor the profiler with open-profiler.sh."
