#!/bin/bash
# Restarts the server by touching RESTART_FLAG and sending the stop command.
cd "$(dirname "$0")"

touch .restart_flag

# Save the server
./stuff.sh save-all

./stuff.sh say Server will go down for restart in 30 seconds.
sleep 14s
./stuff.sh say Server will go down for restart in 15 seconds.
sleep 9s
./stuff.sh say Server will go down for restart in 5 seconds.
./stuff.sh say Server will go down for restart in 4 seconds.
./stuff.sh say Server will go down for restart in 3 seconds.
./stuff.sh say Server will go down for restart in 2 seconds.
./stuff.sh say Server will go down for restart in 1 seconds.

./stuff.sh stop
