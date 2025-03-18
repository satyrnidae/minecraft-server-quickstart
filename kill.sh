#!/bin/bash
# Causes the running screen to exit via SIGTERM.
cd "$(dirname "$0")"

# Read launcher properties
. ./env.sh

echo "Sending SIGTERM to screen process and resuming..."

runshpid=$(sudo -u $RUNAS ps h --ppid $(sudo -u $RUNAS screen -ls | grep $SCREEN | cut -d. -f1) -o pid)

if ps -p $runshpid >/dev/null
then
    sudo -u $RUNAS kill -TERM $runshpid
    echo Waiting 1 minute for process exit...
    sleep 1s
    for ((i=59;i>0;i--)); do
        if [ $i -eq 30 ]; then
            echo Checking for process status in 30 seconds...
        elif [ $i -eq 15 ]; then
            echo Checking for process status in 15 seconds...
        elif [ $i -eq 10 ]; then
            echo Checking for process status in 10 seconds...
        elif [ $i -le 5 ]; then
            if [ $i -eq 1 ]; then
                echo Checking for process status in 1 second...
            else
                echo Checking for process status in $i seconds...
            fi
        fi
        sleep 1s
    done

    if ps -p $runshpid >/dev/null
    then
        echo Kill failed, sending SIGKILL.
        sudo -u $RUNAS kill -KILL $runshpid
        echo Waiting 10 seconds for process death...
        sleep 1s
        for ((i=9;i>0;i--)); do
            if [ $i -le 5 ]; then
                if [ $i -eq 1 ]; then
                    echo Checking for process status in 1 second...
                else
                    echo Checking for process status in $i seconds...
                fi
            fi
            sleep 1s
        done
        if ps -p $runshpid >/dev/null
        then
            echo Failed to terminate run script! Reattaching screen process.
        else
            echo Run script terminated. Reattaching screen process in case it is still active.
        fi
    else
        echo Run script terminated. Reattaching screen process in case it is still active.
    fi

    sudo -u $RUNAS screen -r $SCREEN
else
    echo No process to kill could be found.
fi
