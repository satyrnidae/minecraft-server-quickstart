#!/bin/bash
# Restarts the server by touching RESTART_FLAG and sending the stop command.
cd "$(dirname "$0")"

# Remove the restart flag if it is present.
rm .restart_flag &>/dev/null || true

# Save the server
./stuff.sh save-all
./stuff.sh say Server will shut down in 30 seconds.
sleep 14s
./stuff.sh say Server will shut down in 15 seconds.
sleep 9s
./stuff.sh say Server will shut down in 5 seconds.
./stuff.sh say Server will shut down in 4 seconds.
./stuff.sh say Server will shut down in 3 seconds.
./stuff.sh say Server will shut down in 2 seconds.
./stuff.sh say Server will shut down in 1 seconds.
./stuff.sh stop
