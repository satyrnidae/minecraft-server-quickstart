#!/bin/bash
# Runs a countdown for a specified number of seconds.
# Arguments:
#   - 1:    Required. A number of seconds to count down for.
#   - 2..*: Required. A message explaining what we are counting down to.
# Child scripts:
#   - stuff.sh
# Exit codes:
#   - 64 (EX_USAGE): Set if the required arguments were not provided.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

if [ $# -gt 1 ]; then
    hours=$(($1 / 3600))
    minutes=$(($1 / 60 % 60))
    seconds=$(($1 % 60))
    message=${@:2}
    log "Starting a ${hours}h${minutes}m${seconds}s long countdown until $message."
    color='yellow'
    punct='.'
    if [ $hours -eq 0 ] && [ $minutes -eq 0 ] && [ $seconds -lt 30 ]; then
        color='red'
        punct='!'
    fi

    fmt_time0() { printf "$1" "$message" "$hours" "$minutes" "$seconds" "$color" "$punct"; } # XHXMXS
    fmt_time1() { printf "$1" "$message" "$hours" "$minutes"            "$color" "$punct"; } # XHXM1S, XHXM0S
    fmt_time2() { printf "$1" "$message" "$hours"            "$seconds" "$color" "$punct"; } # XH1MXS, XH0MXS
    fmt_time3() { printf "$1" "$message" "$hours"                       "$color" "$punct"; } # XH1M1S, XH1M0S, XH0M1S, XH0M0S
    fmt_time4() { printf "$1" "$message"          "$minutes" "$seconds" "$color" "$punct"; } # 1HXMXS, 0HXMXS
    fmt_time5() { printf "$1" "$message"          "$minutes"            "$color" "$punct"; } # 1HXM1S, 1HXM0S, 0HXM1S, 0XHM0S
    fmt_time6() { printf "$1" "$message"                     "$seconds" "$color" "$punct"; } # 1H1MXS, 1H0MXS, 0H1MXS, 0H0MXS
    fmt_time7() { printf "$1" "$message"                                "$color" "$punct"; } # 1H1M1S, 1H1M0S, 1H0M1S, 1H0M0S, 0H1M1S, 0H1M0S, 0H0M1S

    if [ $hours -gt 1 ]; then
        if [ $minutes -gt 1 ]; then
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time0 "$LANG_CMP_COUNTDOWN_XHXMXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time1 "$LANG_CMP_COUNTDOWN_XHXM1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time1 "$LANG_CMP_COUNTDOWN_XHXM0S")"
            fi
        elif [ $minutes -eq 1 ]; then
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time2 "$LANG_CMP_COUNTDOWN_XH1MXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time3 "$LANG_CMP_COUNTDOWN_XH1M1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time3 "$LANG_CMP_COUNTDOWN_XH1M0S")"
            fi
        else
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time2 "$LANG_CMP_COUNTDOWN_XH0MXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time3 "$LANG_CMP_COUNTDOWN_XH0M1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time3 "$LANG_CMP_COUNTDOWN_XH0M0S")"
            fi
        fi
    elif [ $hours -eq 1 ]; then
        if [ $minutes -gt 1 ]; then
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time4 "$LANG_CMP_COUNTDOWN_1HXMXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time5 "$LANG_CMP_COUNTDOWN_1HXM1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time5 "$LANG_CMP_COUNTDOWN_1HXM0S")"
            fi
        elif [ $minutes -eq 1 ]; then
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time6 "$LANG_CMP_COUNTDOWN_1H1MXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_1H1M1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_1H1M0S")"
            fi
        else
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time6 "$LANG_CMP_COUNTDOWN_1H0MXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_1H0M1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_1H0M0S")"
            fi
        fi
    else
        if [ $minutes -gt 1 ]; then
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time4 "$LANG_CMP_COUNTDOWN_0HXMXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time5 "$LANG_CMP_COUNTDOWN_0HXM1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time5 "$LANG_CMP_COUNTDOWN_0HXM0S")"
            fi
        elif [ $minutes -eq 1 ]; then
            if [ $seconds -gt 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time6 "$LANG_CMP_COUNTDOWN_0H1MXS")"
            elif [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_0H1M1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_0H1M0S")"
            fi
        else
            if [ $seconds -ne 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time6 "$LANG_CMP_COUNTDOWN_0H0MXS")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_0H0M1S")"
            fi
        fi
    fi


    ovr '%s in %u:%02u:%02u%s Time component color: %- 6s' "$message" "$hours" "$minutes" "$seconds" "$punct" "$color"

    for ((i=$1-1;i>0;--i)); do
        sleep 0.0001s
        hours=$(($i / 3600))
        minutes=$(($i / 60 % 60))
        seconds=$(($i % 60))
        color='yellow'
        punct='.'
        if [ $hours -eq 0 ] && [ $minutes -eq 0 ] && [ $seconds -lt 30 ]; then
            color='red'
            punct='!'
        fi
        ovr '%s in %u:%02u:%02u%s Time component color: %- 6s' "$message" "$hours" "$minutes" "$seconds" "$punct" "$color"
        # Send bcast hourly
        if [ $hours -gt 0 ]; then
            if [ $minutes -eq 0 ] && [ $seconds -eq 0 ]; then
                line_feed
                if [ $hours -eq 1 ]; then
                    ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_1H0M0S")"
                else
                    ./stuff.sh "$BCAST_CMD $(fmt_time3 "$LANG_CMP_COUNTDOWN_XH0M0S")"
                fi
            fi
        # Send bcast at 30 mins, 15 mins, 10 mins, 5 mins, 4 mins, 3 mins, 2 mins, and 1 min
        elif [ $minutes -gt 0 ]; then
            if [ $minutes -eq 30 ] || [ $minutes -eq 15 ] || [ $minutes -eq 10 ] || [ $minutes -le 5 ]; then
                if [ $seconds -eq 0 ]; then
                    line_feed
                    if [ $minutes -eq 1 ]; then
                        ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_0H1M0S")"
                    else
                        ./stuff.sh "$BCAST_CMD $(fmt_time5 "$LANG_CMP_COUNTDOWN_0HXM0S")"
                    fi
                fi
            fi
        # Send bcast at 30 secs, 15 secs, 10 secs, 5 secs, 3 secs, 3 secs, 2 secs, and 1 sec
        elif [ $seconds -eq 30 ] || [ $seconds -eq 15 ] || [ $seconds -eq 10 ] || [ $seconds -le 5 ]; then
            line_feed
            if [ $seconds -eq 1 ]; then
                ./stuff.sh "$BCAST_CMD $(fmt_time7 "$LANG_CMP_COUNTDOWN_0H0M1S")"
            else
                ./stuff.sh "$BCAST_CMD $(fmt_time6 "$LANG_CMP_COUNTDOWN_0H0MXS")"
            fi
        fi

        ovr '%s in %u:%02u:%02u%s Time component color: %- 6s' "$message" "$hours" "$minutes" "$seconds" "$punct" "$color"
    done
else
    fatal $EX_USAGE 'You must provide an amount of time to count down for and a message for the timer.'
fi
sleep 1s
ovr '%s in 0h00m00s%s Time component color: %- 6s\n' "$message" "$punct" "$color"
log 'Countdown complete.'
