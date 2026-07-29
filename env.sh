#!/bin/bash
# Loads launcher properties into environment variables, and creates a default env file if none exists.

set -a
# Exit Codes (sysexits.h and tldp.org)
EX_OK=0             # successful termination

EX__BASE=64         # Base user-defined code, from 64 to 113

EX_USAGE=64         # command line usage error
EX_DATAERR=65       # data format error
EX_NOINPUT=66       # cannot open input
EX_NOUSER=67        # addressee unknown
EX_NOHOST=68        # host name unknown
EX_UNAVAILABLE=69   # service unavailable
EX_SOFTWARE=70      # internal software error
EX_OSERR=71         # system error (e.g., can't fork)
EX_OSFILE=72        # critical OS file missing
EX_CANTCREAT=73     # can't create (user) output file
EX_IOERR=74         # input/output error
EX_TEMPFAIL=75      # temp failure; user is invited to retry
EX_PROTOCOL=76      # remote error in protocol
EX_NOPERM=77        # permission denied
EX_CONFIG=78        # configuration error

EX_GEN_FAILURE=1    # Miscellaneous errors, such as "divide by zero" and other impermissible operations
EX_BUILTINS=2       # Missing keyword or command, or permission problem (and diff return code on a failed binary file comparison)
EX_CANTEXEC=126     # Permission problem or command is not executable
EX_CMDNOTFOUND=127  # Possible problem with $PATH or a typo
EX_INVALID=128      # Invalid argument to the "exit" command

# x86/ARM Signal Faults
EX_SIGHUP=129       # SIGHUP signal
EX_SIGINT=130       # SIGINT signal
EX_SIGQUIT=131      # SIGQUIT signal
EX_SIGILL=132       # Fatal SIGILL signal
EX_SIGTRAP=133      # Fatal SIGTRAP signal
EX_SIGABRT=134      # Fatal SIGABRT signal
EX_SIGIOT=134       # Fatal SIGIOT signal
EX_SIGBUS=135       # Fatal SIGBUS signal
EX_SIGFPE=136       # Fatal SIGFPE signal
EX_SIGKILL=137      # Fatal SIGKILL signal
EX_SIGUSR1=138      # Fatal SIGUSR1 signal
EX_SIGSEGV=139      # Fatal SIGSEGV signal
EX_SIGUSR2=140      # Fatal SIGUSR2 signal
EX_SIGPIPE=141      # Fatal SIGPIPE signal
EX_SIGALRM=142      # Fatal SIGALRM signal
EX_SIGTERM=143      # Fatal SIGTERM signal
EX_SIGSTKFLT=144    # Fatal SIGSTKFLT signal
EX_SIGCHLD=145      # Fatal SIGCHLD signal
EX_SIGCONT=146      # Fatal SIGCONT signal
EX_SIGSTOP=147      # Fatal SIGSTOP signal
EX_SIGTSTP=148      # Fatal SIGTSTP signal
EX_SIGTTIN=149      # Fatal SIGTTIN signal
EX_SIGTTOU=150      # Fatal SIGTTOU signal
EX_SIGURG=151       # Fatal SIGURG signal
EX_SIGXCPU=152      # Fatal SIGXCPU signal
EX_SIGXFSZ=153      # Fatal SIGXFSZ signal
EX_SIGVTALRM=154    # Fatal SIGVTALRM signal
EX_SIGPROF=155      # Fatal SIGPROF signal
EX_SIGWINCH=156     # Fatal SIGWINCH signal
EX_SIGIO=157        # Fatal SIGIO signal
EX_SIGPOLL=157      # Fatal SIGPOLL signal
EX_SIGPWR=158       # Fatal SIGPWR signal
EX_SIGSYS=159       # Fatal SIGSYS signal
set +a

# Common functions
ovr() {
    printf "\r$1" "${@:2}"
}
line_feed() {
    printf '\n'
}

if [[ -z "${__SPIN_COUNTER}" ]]; then
    set -a
    __SPIN_COUNTER=0;
    set +a
fi
spinner() {
    local spin_frames spindex
    spin_frames=('   ' '.  ' '.. ' '...' ' ..' '  .' '   ')
    spindex=$(($__SPIN_COUNTER % ${#spin_frames[@]}))
    set -a
    __SPIN_COUNTER=$(($__SPIN_COUNTER + 1))
    set +a

    ovr "$1%s" "${@:2}" "${spin_frames[$spindex]}"
}

# Logging
banner() {
    printf '%s ------ %s ------\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >>./quickstart.log 2>&1
}
debug() {
    if [[ "$DEBUG" = '1' ]]; then
        printf 'DEBUG: %s\n' "$*"
        printf '%s DEBUG: %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >>./quickstart.log 2>&1
    fi
}
log() {
    printf '%s\n' "$*"
    printf '%s INFO:  %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >>./quickstart.log 2>&1
}
warning() {
    printf 'WARNING: %s\n' "$*" >&2
    printf '%s WARN:  %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >>./quickstart.log 2>&1
}
error() {
    printf 'ERROR: %s\n' "$*" >&2
    printf '%s ERROR: %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >>./quickstart.log 2>&1
}
fatal() {
    local exit_code
    exit_code=$1; shift || exit $EX_USAGE
    printf 'FATAL: %s (Exit code %s)\n' "$*" "$exit_code" >&2
    printf '%s FATAL: %s (Exit code %s)\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" "$exit_code" >>./quickstart.log 2>&1
    exit $exit_code
}

# Dependencies
optional() {
    command -v "$*" >/dev/null 2>&1 || {
        warning 'Failed to locate optional dependency "'"$*"'". Please ensure the file exists or the command is on your PATH.'
    }
}
depends() {
    command -v "$*" >/dev/null 2>&1 || {
        fatal $EX_CMDNOTFOUND 'Failed to locate required dependency "'"$*"'". Please ensure the file exists or the command is on your PATH';
    }
}

# Network requests
http_status_message() {
    case "$1" in
        300) echo 'Multiple Choices' ;;
        301) echo 'Moved Permanently' ;;
        302) echo 'Found' ;;
        304) echo 'Not Modified' ;;
        307) echo 'Temporary Redirect' ;;
        308) echo 'Permanent Redirect' ;;
        400) echo 'Bad Request' ;;
        401) echo 'Unauthorized' ;;
        403) echo 'Forbidden' ;;
        404) echo 'Not Found' ;;
        405) echo 'Method Not Allowed' ;;
        408) echo 'Request Timeout' ;;
        409) echo 'Conflict' ;;
        410) echo 'Gone' ;;
        422) echo 'Unprocessable Entity' ;;
        425) echo 'Too Early' ;;
        429) echo 'Too Many Requests' ;;
        500) echo 'Internal Server Error' ;;
        501) echo 'Not Implemented' ;;
        502) echo 'Bad Gateway' ;;
        503) echo 'Service Unavailable' ;;
        504) echo 'Gateway Timeout' ;;
        *)   echo 'HTTP Error' ;;
    esac
}
check_http() {
    local curl_exit=$1
    local http_code=$2
    local url=$3
    if [ "$curl_exit" -ne 0 ]; then
        fatal $EX_UNAVAILABLE "Could not reach $url (curl exit code $curl_exit). Check your network connection and try again."
    fi
    if ! [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        fatal $EX_UNAVAILABLE "$url returned HTTP $http_code ($( http_status_message "$http_code" )). The remote server may be unavailable. Please update the quicklauncher or try again later."
    fi
}
http_get_json() {
    local url=$1
    local result_var=$2
    local filter=$3
    local response http_code curl_exit body
    response=$( curl -s -L -w '\n%{http_code}' -X GET -H 'accept: application/json' "$url" )
    curl_exit=$?
    http_code=$( printf '%s' "$response" | tail -n1 )
    check_http "$curl_exit" "$http_code" "$url"
    body=$( printf '%s' "$response" | sed '$d' )
    if [ -n "$filter" ]; then
        printf -v "$result_var" '%s' "$( printf '%s' "$body" | jq -r "$filter" )"
    else
        printf -v "$result_var" '%s' "$body"
    fi
}
http_get_file() {
    local url=$1
    local output=$2
    local http_code curl_exit
    http_code=$( curl -L -X GET -H 'accept: application/json' --output "$output" -w '%{http_code}' "$url" )
    curl_exit=$?
    check_http "$curl_exit" "$http_code" "$url"
}

# Signal traps
extract_trap_cmd() {
    if ! [[ "$3" = "" ]]; then
        printf '%s\n' "$3"
    fi
}
prepend_trap() {
    local trap_add_cmd trap_add_name
    trap_add_cmd=$1; shift || fatal $EX_USAGE "${FUNCNAME} usage error"
    for trap_add_name in "$@"; do
        trap -- "$(
            printf '%s\n' "${trap_add_cmd}"
            eval "extract_trap_cmd $(trap -p "${trap_add_name}" || "")"
        )" "${trap_add_name}" \
            || fatal "unable to add to trap ${trap_add_name}"
    done
}
declare -f -t prepend_trap
append_trap() {
    local trap_add_cmd trap_add_name
    trap_add_cmd=$1; shift || fatal $EX_USAGE "${FUNCNAME} usage error"
    for trap_add_name in "$@"; do
        trap -- "$(
            eval "extract_trap_cmd $(trap -p "${trap_add_name}" || "")"
            printf '%s\n' "${trap_add_cmd}"
        )" "${trap_add_name}" \
            || fatal "unable to add to trap ${trap_add_name}"
    done
}
declare -f -t append_trap

properties_file='./quickstart.env'

# Initialize the properties file if it doesn't yet exist.
if ! [ -f $properties_file ]; then
    debug "Initializing properties file $(realpath $properties_file)."
    touch $properties_file
    echo '#!/bin/bash' > $properties_file
    echo '# This file defines the environment variables available to scripts which source env.sh.' >> $properties_file
    echo '# Environment variables cannot contain spaces or periods in their names.' >> $properties_file
    echo '# You may define your own environment variables at the top of this file.' >> $properties_file
    echo '' >> $properties_file
    echo '# Add your custom environment variables here.' >> $properties_file
    echo '' >> $properties_file
    echo '##### DO NOT DELETE ENTRIES BELOW THIS LINE #####' >> $properties_file
    echo '' >> $properties_file
    echo '# Common environment variables' >> $properties_file
    echo 'SCREEN=minecraft_server # The name of the screen that the server will run under.' >> $properties_file
    echo "RUNAS=$(whoami) # The user with whom the screen will be launched." >> $properties_file
    echo '' >> $properties_file
    echo '# start.sh options' >> $properties_file
    echo 'LAUNCH_CMD="./run.sh"' >> $properties_file
    echo '' >> $properties_file
    echo '# run.sh options' >> $properties_file
    echo 'RUN_SCRIPT=papermc.sh     # Must match the filename of a script in the "runs/" folder, with extension' >> $properties_file
    echo 'RUN_SCRIPT_ARGS=(--nogui) # These arguments are passed directly to the script file by run.sh as a bash array. Add more entries for more arguments, such as (--nogui --universe saves --world "my world").' >> $properties_file
    echo 'RESTART_WAIT_TIME=10s' >> $properties_file
    echo '' >> $properties_file
    echo '# Common arguments for all runs/ scripts' >> $properties_file
    echo "JVM='$(command -v java || echo java)' # The command to launch the Java Virtual Machine." >> $properties_file
    echo '' >> $properties_file
    echo '# Common server commands used at runtime from certain scripts.' >> $properties_file
    echo 'BCAST_CMD="title @a actionbar" # Broadcast command for the server. Must support chat component strings as the final argument.' >> $properties_file
    echo 'KICK_CMD="kick @a"             # Command to kick all players from the server. Must support strings and chat component strings as the final argument.' >> $properties_file
    echo '' >> $properties_file
    echo '# runs/papermc.sh options' >> $properties_file
    echo 'PAPERCRAFT_JAR=dynamic    # Set this to dynamic to download the latest build from Paper''s API, or set to a specific jar file.' >> $properties_file
    echo 'PAPERCRAFT_VERSION=latest # If PAPERCRAFT_JAR is set to dynamic, this will determine which Minecraft version is downloaded. Set to latest to use the latest version.' >> $properties_file
    echo '' >> $properties_file
    echo '# runs/forge.sh options' >> $properties_file
    echo 'FORGE_ARGS=libraries/net/minecraftforge/forge/1.19.2-43.4.16/unix_args.txt # Set this to the args file from your forge install''s default script.' >> $properties_file
    echo '' >> $properties_file
    echo '# runs/minecraft.sh options' >> $properties_file
    echo 'MINECRAFT_JAR=dynamic     # Set this to dynamic to download the requested version from Mojang''s API, or set to a specific jar file.' >> $properties_file
    echo 'MINECRAFT_VERSION=latest  # If MINECRAFT_JAR is set to dynamic, this will determine which Minecraft version is downloaded. Set to latest for the latest release, latest-snapshot for the latest snapshot, or an exact version id such as 1.20.4.' >> $properties_file
    echo '' >> $properties_file
    echo '# runs/example.sh options' >> $properties_file
    echo 'EXAMPLE_SCRIPT_JARFILE=server.jar # Set this to the name of the jar file you want to run.' >> $properties_file
    echo '' >> $properties_file
    echo '# backup.sh options' >> $properties_file
    echo 'BACKUP_DIRECTORY="backups/" # Destination folder for backups. If using rsync or rdiff201, change this to use a folder outside the current directory.' >> $properties_file
    echo '# Select one BACKUP_METHOD from the options below.' >> $properties_file
    echo 'BACKUP_METHOD=rdiff         # Legacy rdiff-backup CLI. Uses include-filelist.txt to designate included and excluded files and folders. Only enable if your rdiff-backup install supports the deprecated pre-201 CLI.' >> $properties_file
    echo '#BACKUP_METHOD=rdiff201     # New rdiff-backup CLI. Use an external or network folder for BACKUP_DIRECTORY, as include-filelist is no longer used.' >> $properties_file
    echo '#BACKUP_METHOD=rsync        # Use rsync instead of rdiff-backup. Use an external or network folder for BACKUP_DIRECTORY, as no files are excluded.' >> $properties_file
    echo '#BACKUP_METHOD=scp          # Use secure copy for the backup. Use an external or network folder for BACKUP_DIRECTORY, as no files will be excluded.' >> $properties_file
    echo '#BACKUP_ARGS=(--no-acls)    # Extra args for the backup command as a bash array. For rdiff-backup, these come after the "backup" command. For others, they are passed directly to the command.' >> $properties_file
    echo '' >> $properties_file
    echo '# autorestart.sh / autoreboot.sh task properties' >> $properties_file
    echo 'RESTART_TIMER=1800               # Time in seconds to wait before restarting the server automatically.' >> $properties_file
    echo 'RESTART_ESTIMATE="5 minutes"     # Approximate duration of a restart.' >> $properties_file
    echo 'FULL_CYCLE_ESTIMATE="10 minutes" # Approximate duration of a full server cycle.' >> $properties_file
    echo '' >> $properties_file
    echo '# watchdog.sh task properties' >> $properties_file
    echo '# To use the watchdog system you must have query enabled on your Minecraft server and have MCI installed.' >> $properties_file
    echo "MCLI='$(command -v mcli || echo mcli)'       # Path to the MCLI executable." >> $properties_file
    echo 'ENABLE_QUERY=0    # Set to 1 to enable this functionality' >> $properties_file
    echo 'QUERY_PORT=25567  # Set to the query_port of your server, available in server.properties' >> $properties_file
    echo 'QUERY_TIMEOUT=300 # The time, in seconds, to wait for the query result. May need to be adjusted if the startup time for your server is very long.' >> $properties_file
    echo 'MAX_QUERY_FAILS=3 # The number of times that the query can fail before the server is killed and restarted.' >> $properties_file
fi

sys_locale=$(locale | grep LANG | cut -d = -f2 | cut -d . -f1)
if ! [ -f ./lang/$sys_locale.lang ]; then
    debug "Failed to find a locale file matching system locale $sys_locale. Defaulting to en_US."
    sys_locale='en_US'
fi

set -a
debug 'Setting default property values.'
SCREEN='minecraft_server'
RUNAS="$(whoami)"
LAUNCH_CMD='./run.sh'
RUN_SCRIPT='papermc.sh'
RUN_SCRIPT_ARGS=(--nogui)
RESTART_WAIT_TIME='10s'
JVM="$(command -v java)"
BCAST_CMD='title @a actionbar'
KICK_CMD='kick @a'
PAPERCRAFT_JAR='dynamic'
PAPERCRAFT_VERSION='latest'
FORGE_ARGS='@libraries/net/minecraftforge/forge/1.19.2-43.4.16/unix_args.txt'
MINECRAFT_JAR='dynamic'
MINECRAFT_VERSION='latest'
EXAMPLE_SCRIPT_JARFILE='server.jar'
BACKUP_DIRECTORY="backups/"
BACKUP_METHOD='rdiff'
BACKUP_ARGS=()
RESTART_TIMER='1800'
RESTART_ESTIMATE='5 minutes'
FULL_CYCLE_ESTIMATE='10 minutes'
MCLI="$(command -v mcli || echo mcli)"
ENABLE_QUERY='0'
QUERY_PORT='25567'
QUERY_TIMEOUT='300'
MAX_QUERY_FAILS=3

# Load values from PROPERTIES
debug "Loading real properties from $(realpath $properties_file)."
. $properties_file

# Load locale
debug "Loading locale file from $(realpath "./lang/$sys_locale.lang")."
. "./lang/$sys_locale.lang"
set +a

# Autoaccept EULA
if ! [ -f './eula.txt' ]; then
    printf 'eula=true\n' >./eula.txt
fi
