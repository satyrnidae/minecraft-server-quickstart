#!/bin/bash
# Executes and restarts the minecraft server within the screen instance.
# Per-distribution run scripts can be found in run.sh.d
cd "$(dirname "$0")"

# Needed environment variables
#   RUNSCRIPT
#   RESTARTWAITTIME
. ./env.sh

# Main run loop
while :;
do

    # Remove the restart flag which will be used to determine if the main loop should break or not.
    # If the restart flag is present after the run script completes, regardless of exit code,
    #   then we restart the server as though it crashed.
    if [ -f .restart_flag ]; then
        rm .restart_flag &>/dev/null
    fi
    
    # Executes the script definition by name.
    script="./runs/$RUN_SCRIPT.sh"
    if [ ! -f $script ]; then
        printf 'There is no script named %s within the runs/ directory.\n' "${RUN_SCRIPT}" >&2
        echo "Please either select an existing script in runs/ or create your own." >&2
        exit 255
    else
        $script $RUN_SCRIPT_ARGS || {
            printf '\nDetected server crash (exit code: %s)!\n' "${?}" >&2
            touch .restart_flag
        }
    fi

    # If the restart flag exists, delete it and allow the loop to continue.
    if [ -f .restart_flag ]; then
        rm .restart_flag || {
            printf '\nFailed to delete the restart flag (exit code %s) - exiting!\n' "${?}" >&2
            exit 1
        }
    else break; fi

    echo "Restarting server in $RESTART_WAIT_TIME. Press Ctrl+C to abort."
    sleep $RESTART_WAIT_TIME || break

done
