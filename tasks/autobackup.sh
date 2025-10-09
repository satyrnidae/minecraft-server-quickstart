#!/bin/bash
# Performs an automatic backup of the entire server to the NAS
# Utilizes backup.sh and stuff.sh to interact with the server as it is running
# Dependencies:
#   - screen (Optional)
#   - rdiff-backup (Optional)
#   - rsync (Optional)
#   - scp (Optional)
# Child scripts:
#   - stuff.sh
#   - backup.sh
# Configuration variables:
#   - RUNAS:            The user with whom the screen would launch.
#   - SCREEN:           The name of the screen that the server would run under.
#   - BCAST_CMD:        Broadcast command for the server. Must support chat component strings as the final argument.
#   - BACKUP_METHOD:    Select one BACKUP_METHOD from the provided options in quickstart.env
#   - BACKUP_DIRECTORY: Destination folder for backups. If using rsync or rdiff201, change this to use a folder outside the current directory.
# Exit codes:
#   - 127 (EX_CMDNOTFOUND): Your selected backup method was not executable and/or available on the PATH.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

optional screen

# Make sure screen is active
if ! command -v screen >/dev/null; then
    log 'Running backup without notify as screen is not present on the PATH.'
    ./backup.sh || fatal $? 'Backup failed!'
elif ! sudo -u $RUNAS screen -list | grep -q $SCREEN; then
    log 'Running backup without notify as there is no screen "'"$SCREEN"'" running.'
    ./backup.sh || fatal $? 'Backup failed!'
else
    # Trap exit to turn automatic saving ON on script exit
    prepend_trap './stuff.sh save-on; ./stuff.sh '\'"$BCAST_CMD $LANG_CMP_AUTOBACKUP_COMPLETE"\'';' EXIT

    log 'Starting unattended backup...'

    # Announce backup start
    ./stuff.sh "$BCAST_CMD $LANG_CMP_AUTOBACKUP_START_COMPONENT"

    # Turn automatic saving OFF
    ./stuff.sh save-off
    sleep 1s
    ./stuff.sh save-all
    # Wait for the server to finish saving
    log 'Waiting for server save to complete...'
    sleep 30s

    log 'Backing up with the backup script...'

    # Run backup
    ./backup.sh || {
        ./stuff.sh "$BCAST_CMD $LANG_CMP_AUTOBACKUP_FAILED_COMPONENT"
        fatal $? 'Backup failed!'
    }
fi
