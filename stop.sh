#!/bin/bash
# Stops the server by removing RESTART_FLAG and sending the stop command.
cd "$(dirname "$0")"

# Remove the restart flag if it is present.
rm .restart_flag &>/dev/null || true

# Sleep and warning subroutine
if [ $# -gt 0 ]; then

    minutes=$(($1 / 60))
    seconds=$(($1 % 60))
    if [ $minutes -eq 1 ]; then
        if [ $seconds -eq 1 ]; then
            ./stuff.sh say Server will shut down in 1 minute and 1 second.
        elif [ $seconds -eq 0 ]; then
            ./stuff.sh say Server will shut down in 1 minute.
        else
            ./stuff.sh say Server will shut down in 1 minutes and $seconds seconds.
        fi
    elif [ $minutes -gt 0 ]; then
        if [ $seconds -eq 1 ]; then
            ./stuff.sh say Server will shut down in $minutes minutes and 1 second.
        elif [ $seconds -eq 0 ]; then
            ./stuff.sh say Server will shut down in $minutes minutes.
        else
            ./stuff.sh say Server will shut down in $minutes minutes and $seconds seconds.
        fi
    else
        if [ $1 -eq 1 ]; then
            ./stuff.sh say Server will shut down in 1 second.
        else
            ./stuff.sh say Server will shut down in $1 seconds.
        fi
    fi

    sleep 1s
    for ((i=$1-1;i>0;--i)); do
        if [ $(($i % 30)) -eq 0 ]; then
            minutes=$(($i / 60))
            seconds=$(($i % 60))
            if [ $minutes -eq 1 ]; then
                if [ $seconds -eq 0 ]; then
                    ./stuff.sh say Server will shut down in 1 minute.
                else
                    ./stuff.sh say Server will shut down in 1 minute and $seconds seconds.
                fi
            elif [ $minutes -gt 0 ]; then
                if [ $seconds -eq 0 ]; then
                    ./stuff.sh say Server will shut down in $minutes minutes.
                else
                    ./stuff.sh say Server will shut down in $minutes minutes and $seconds seconds.
                fi
            else
                ./stuff.sh say Server will shut down in $i seconds.
            fi
        elif [ $i -eq 15 ]; then
            ./stuff.sh say Server will shut down in 15 seconds!
        elif [ $i -eq 10 ]; then
            ./stuff.sh say Server will shut down in 10 seconds!
        elif [ $i -le 5 ]; then
            if [ $i -eq 1 ]; then
                ./stuff.sh say Server will shut down in 1 second!
            else
                ./stuff.sh say Server will shut down in $i seconds!
            fi
        fi
        sleep 1s
    done

fi

./stuff.sh save-all
sleep 1s
./stuff.sh stop
