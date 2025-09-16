#!/bin/bash
# Runs a countdown for a specified number of seconds.

# Set directory to root
cd "$(dirname "$0")/.."

# Read environment variables
. ./env.sh

if [ $# -gt 0 ]; then
    minutes=$(($1 / 60))
    seconds=$(($1 % 60))
    message=${@:2}
    color="yellow"
    punct="."
    if [ $minutes -eq 0 ] && [ $seconds -lt 30 ]; then
        color="red"
        punct="!"
    fi
    if [ $minutes -eq 1 ]; then
        if [ $seconds -eq 1 ]; then
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"1 minute and 1 second\",\"color\":\"$color\"},\"$punct\"]"
        elif [ $seconds -eq 0 ]; then
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"1 minute\",\"color\":\"$color\"},\"$punct\"]"
        else
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"1 minute and $seconds seconds\",\"color\":\"$color\"}, \"$punct\"]"
        fi
    elif [ $minutes -eq 0 ]; then
        if [ $seconds -eq 1 ]; then
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"1 second\",\"color\":\"$color\"},\"$punct\"]"
        else
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$seconds seconds\",\"color\":\"$color\"},\"$punct\"]"
        fi
    else
        if [ $seconds -eq 1 ]; then
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes and 1 second\",\"color\":\"$color\"},\"$punct\"]"
        elif [ $seconds -eq 0 ]; then
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes\",\"color\":\"$color\"},\"$punct\"]"
        else
            ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes and $seconds seconds\",\"color\":\"$color\"}, \"$punct\"]"
        fi
    fi
    printf '\r%s in %um%us%s Time component color: %s            ' "$message" "$minutes" "$seconds" "$punct" "$color"

    for ((i=$1-1;i>0;--i)); do
        sleep 1s
        minutes=$(($i / 60))
        seconds=$(($i % 60))
        color="yellow"
        punct="."
        if [ $minutes -eq 0 ] && [ $seconds -lt 30 ]; then
            color="red"
            punct="!"
        fi
        # Above 30 minutes, send bcast at each 30 minute mark
        if [ $minutes -ge 30 ]; then
            if [ $(($minutes % 30)) -eq 0 ] && [ $seconds -eq 0 ]; then
                ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes\",\"color\":\"$color\"},\"$punct\"]"
            fi
        # From 30 to ten minutes, send bcast at each five minute mark
        elif [ $minutes -ge 10 ]; then
            if [ $(($minutes % 5)) -eq 0 ] && [ $seconds -eq 0 ]; then
                ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes\",\"color\":\"$color\"},\"$punct\"]"
            fi
        # From 10 mins to five minutes, send bcast every minute
        elif [ $minutes -ge 5 ]; then
            if [ $seconds -eq 0 ]; then
                ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes\",\"color\":\"$color\"},\"$punct\"]"
            fi
        # At 5 mins and below, send bcast every 30 seconds, plus exceptions
        else
            if [ $(($seconds % 30)) -eq 0 ]; then
                if [ $minutes -eq 1 ]; then
                    # Seconds will never equal 1, only 30 or zero. We don't need to handle the singular case here.
                    if [ $seconds -eq 0 ]; then
                        ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"1 minute\",\"color\":\"$color\"},\"$punct\"]"
                    else
                        ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"1 minute and $seconds seconds\",\"color\":\"$color\"},\"$punct\"]"
                    fi
                elif [ $minutes -eq 0 ]; then
                    # This only applies to 30 seconds; we don't handle 0:00 at all, since that's up to the caller script.
                    ./stuff.sh ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$seconds seconds\",\"color\":\"$color\"},\"$punct\"]"
                else
                    # Seconds will never equal 1, only 30 or zero. We don't need to handle the singular case here.
                    if [ $seconds -eq 0 ]; then
                        ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes\",\"color\":\"$color\"},\"$punct\"]"
                    else
                        ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$minutes minutes and $seconds seconds\",\"color\":\"$color\"},\"$punct\"]"
                    fi
                fi
            fi
        fi
        # At 15 and 10 seconds, and at 5 seconds and below, send bcast immediately
        if [ $minutes -eq 0 ]; then
            if [ $seconds -eq 15 ] || [ $seconds -eq 10 ] || [ $seconds -le 5 ]; then
                if [ $seconds -eq 1 ]; then
                    ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"1 second\",\"color\":\"$color\"},\"$punct\"]"
                # We don't handle 0:00 at all; that's up to the caller script.
                else
                    ./stuff.sh "$BCAST_CMD [\"$message in\",{\"text\":\"$seconds seconds\",\"color\":\"$color\"},\"$punct\"]"
                fi
            fi
        fi
        printf '\r%s in %um%us%s Time component color: %s            ' "$message" "$minutes" "$seconds" "$punct" "$color"
    done
fi
sleep 1s
printf '\rDone!                                                                 '
