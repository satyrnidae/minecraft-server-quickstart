#!/bin/bash
# When combined with a call to /sbin/shutdown -r +35, prepares the server for an
#   impending system reboot.
# Dependencies:
#   - screen
# Child scripts:
#   - countdown.sh
#   - stuff.sh
#   - kill.sh
# Configuration variables:
#   - RUNAS:               The user with whom the screen would launch.
#   - SCREEN:              The name of the screen that the server would run under.
#   - BCAST_CMD:           Broadcast command for the server. Must support chat component strings as the final argument.
#   - KICK_CMD:            Command to kick all players from the server. Must support strings and chat component strings as the final argument.
#   - RESTART_TIMER:       Time in seconds to wait before restarting the server automatically.
#   - FULL_CYCLE_ESTIMATE: Approximate duration of a full server cycle.
# Exit codes:
#   - 71  (EX_OSERR):       The server did not respond to SIGKILL
#   - 127 (EX_CMDNOTFOUND): Missing a dependency

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

depends screen
# if the SCREEN is not active we can skip the countdown part
if sudo -u $RUNAS screen -list | grep -q $SCREEN; then
    log 'Notifying users of the impending restart and stopping the server.'
    # Configurable countdown.
    ./tools/countdown.sh $RESTART_TIMER "$LANG_STR_AUTOREBOOT_COUNTDOWN"
    ./stuff.sh "$BCAST_CMD $LANG_CMP_AUTOREBOOT_GOODBYE"
    ./stuff.sh "$KICK_CMD \"$(printf "$LANG_CMP_AUTOREBOOT_KICKREASON_1S" "$FULL_CYCLE_ESTIMATE")\""
    ./stuff.sh 'stop'
    # Clear restart flag
    rm -f .restart_flag > /dev/null
    # Give the server time to stop.
    sleep 2m
fi

log 'Forcing the server to close if it is still active.'

# Clear restart flag
rm -f .restart_flag > /dev/null

# Kill server process if it got stuck.
./kill.sh || {
    fatal $? 'Failed to force kill the server.'
}
