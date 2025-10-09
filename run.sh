#!/bin/bash
# Executes and restarts the minecraft server within the screen instance.
# Per-distribution run scripts can be found in runs/

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

# Main run loop
while :;
do
    # Remove the watchdog lockfile if present.
    if [ -f .watchdog_lock ]; then
        rm -f .watchdog_lock >/dev/null 2>&1 || {
            fatal $EX_IOERR "Failed to delete the watchdog lockfile (Exit code $?)."
        }
    fi

    # Remove the restart flag which will be used to determine if the main loop should break or not.
    # If the restart flag is present after the run script completes, regardless of exit code,
    #   then we restart the server as though it crashed.
    if [ -f .restart_flag ]; then
        rm -f .restart_flag >/dev/null 2>&1 || {
            warning 'Failed to delete the restart flag. Server may restart with a 0 exit code.'
        }
    fi

    # Executes the script definition by name.
    script="./runs/$RUN_SCRIPT"
    if [ ! -f $script ]; then
        error "There is no script named $RUN_SCRIPT within the runs/ directory."
        fatal $EX_CONFIG 'Please either select an existing script in runs/ or create your own.'
    else
        # If watchdog is enabled, create .watchdog_lock
        if [ $ENABLE_QUERY -gt 0 ]; then
            touch .watchdog_lock
            prepend_trap 'rm -f .watchdog-lock || warning "Failed to delete the watchdog lockfile!"' EXIT
        fi

        log "Executing run script $script with args: $RUN_SCRIPT_ARGS"

        $script $RUN_SCRIPT_ARGS || {
            exit_code=$?
            if [[ "$exit_code" = "$EX_CONFIG" ]]; then
                fatal $EX_CONFIG "Detected an unrecoverable configuration error. Please verify your quickstart.env file."
            elif [[ "$exit_code" = "$EX_SIGINT" ]]; then
                fatal $EX_SIGINT "SIGINT detected. The server will not restart."
            else
                error "Detected server crash (Exit code $exit_code)! Marking server for a restart."
                touch .restart_flag >/dev/null 2>&1 || {
                    fatal $EX_IOERR "Failed to touch .restart_flag (Exit code $?)."
                }
            fi
        }
    fi

    # Remove the watchdog lockfile if present.
    if [ -f .watchdog_lock ]; then
        rm -f .watchdog_lock >/dev/null 2>&1 || {
            fatal $EX_IOERR "Failed to delete the watchdog lockfile (Exit code $?)."
        }
    fi

    # If the restart flag exists, delete it and allow the loop to continue.
    if [ -f .restart_flag ]; then
        rm -f .restart_flag  >/dev/null 2>&1 || {
            fatal $EX_IOERR "Failed to delete the restart flag (Exit code $?)."
        }
    else break; fi

    log "Restarting server in $RESTART_WAIT_TIME. Press Ctrl+C to abort."
    trap "fatal $EX_SIGINT 'User cancelled the restart process.'" INT
    sleep $RESTART_WAIT_TIME || break
    trap - INT
done
