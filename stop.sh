#!/bin/bash
# Restarts the server by touching RESTART_FLAG and sending the stop command.
cd "$(dirname "$0")"

# Remove the restart flag if it is present.
rm .restart_flag &>/dev/null || true

# Save the server
./stuff.sh save-all

echo "Waiting for server save to complete..."
sleep 30s

./stuff.sh stop
