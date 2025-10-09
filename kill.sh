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
    for ((i=240;i>0;i--)); do
        if [ $i -gt 120 ]; then
            spinner 'Checking for process status in  1 minute '
        elif [ $i -gt 60 ]; then
            spinner 'Checking for process status in 30 seconds'
        elif [ $i -gt 40 ]; then
            spinner 'Checking for process status in 15 seconds'
        elif [ $i -ge 20 ]; then
            spinner 'Checking for process status in 10 seconds'
        elif [ $i -gt 4 ]; then
            spinner 'Checking for process status in  %s seconds' $(($i / 4 + 1))
        else
            spinner 'Checking for process status in  1 second '
        fi
        sleep 0.25s
    done
    ovr 'Checking for process status now.            \n'

    if ps -p $pid >/dev/null; then
        warning "Process $pid failed to respond to SIGTERM in time, sending SIGKILL..."
        sudo -u $RUNAS kill -KILL $pid
        log 'Waiting 10 seconds for process death.'
        for ((i=40;i>0;i--)); do
            if [ $i -ge 20 ]; then
                spinner 'Checking for process status in 10 seconds'
            elif [ $i -gt 4 ]; then
                spinner 'Checking for process status in  %s seconds' $(($i / 4 + 1))
            else
                spinner 'Checking for process status in  1 second '
            fi
            sleep 0.25s
        done
        ovr 'Checking for process status now.            \n'

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
