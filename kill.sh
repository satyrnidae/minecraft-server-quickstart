#!/bin/bash
# Causes the running screen to exit via SIGTERM.
# Dependencies:
#   - screen
# Child scripts:
#   - attach.sh
# Configuration variables:
#   - RUNAS:  The user with whom the screen would launch.
#   - SCREEN: The name of the screen that the server would run under.
# Exit codes:
#   - 71  (EX_OSERR):       The server did not respond to SIGKILL
#   - 127 (EX_CMDNOTFOUND): Missing a dependency

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

depends screen
if ! sudo -u $RUNAS screen -ls | grep -q $SCREEN; then
    fatal $EX_OK "There was no screen $SCREEN present for $RUNAS."
fi

pid=$(ps h -u $RUNAS --ppid $(sudo -u $RUNAS ls /run/screen/S-$RUNAS | grep $SCREEN | cut -d . -f1) -o pid | awk '{$1=$1};1')
if ps -p $pid >/dev/null; then
    cmd=$(ps h -p $pid -o cmd)
    log "Found process $pid with command $cmd, sending SIGTERM..."
    sudo -u $RUNAS kill -TERM $pid
    log 'Waiting 1 minute for process exit.'
    printf '\rChecking for process status in 30 seconds...'
    for ((i=60;i>0;i--)); do
        if [ $i -eq 30 ]; then
            printf '\rChecking for process status in 30 seconds...'
        elif [ $i -eq 15 ]; then
            printf '\rChecking for process status in 15 seconds...'
        elif [ $i -eq 10 ]; then
            printf '\rChecking for process status in 10 seconds...'
        elif [ $i -le 5 ]; then
            if [ $i -eq 1 ]; then
                printf '\rChecking for process status in  1 second... '
            else
                printf '\rChecking for process status in  %s seconds...' $i
            fi
        fi
        sleep 1s
    done
    line_feed

    if ps -p $pid >/dev/null; then
        warning "Process $pid failed to respond to SIGTERM in time, sending SIGKILL..."
        sudo -u $RUNAS kill -KILL $pid
        log 'Waiting 10 seconds for process death.'
        printf '\rChecking for process status in 10 seconds...'
        for ((i=10;i>0;i--)); do
            if [ $i -le 5 ]; then
                if [ $i -eq 1 ]; then
                    printf '\rChecking for process status in  1 second... '
                else
                    printf '\rChecking for process status in  %s seconds...' $i
                fi
            fi
            sleep 1s
        done
        line_feed

        if ps -p $pid >/dev/null; then
            fatal $EX_OSERR 'Failed to terminate run script!'
        fi
    fi

    log 'Run script terminated. Reattaching screen process in case it is still active.'
    ./attach.sh
else
    warning 'No process to kill could be found.'
fi

if [ -f .watchdog_lock ]; then
    rm -f .watchdog_lock >/dev/null
fi
