#!/bin/bash
# Restarts the server by touching RESTART_FLAG and sending the stop command.
cd "$(dirname "$0")"

touch .restart_flag
./stuff.sh stop
