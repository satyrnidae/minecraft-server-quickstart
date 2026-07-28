#!/bin/bash
# Backs up the server to the BACKUP_DIRECTORY using BACKUP_METHOD
# Dependencies:
#   - rdiff-backup (Optional)
#   - rsync (Optional)
#   - scp (Optional)
# Configuration variables:
#   - BACKUP_METHOD:    Select one BACKUP_METHOD from the provided options in quickstart.env
#   - BACKUP_DIRECTORY: Destination folder for backups. If using rsync or rdiff201, change this to use a folder outside the current directory.
#   - BACKUP_ARGS:      Extra args for the backup command as a bash array.
# Exit codes:
#   - 127 (EX_CMDNOTFOUND): Your selected backup method was not executable and/or available on the PATH.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

if [ $BACKUP_METHOD == 'rdiff201' ]; then
    log "Backing up entire server to $BACKUP_DIRECTORY with rdiff-backup, new CLI."
    depends rdiff-backup
    rdiff-backup --force --api-version 201 --terminal-verbosity 5 --ssh-compression backup "${BACKUP_ARGS[@]}" . $BACKUP_DIRECTORY
elif [ $BACKUP_METHOD == 'rdiff' ]; then
    log "Backing up entire server to $BACKUP_DIRECTORY with rdiff-backup, legacy CLI w/ excludes."
    depends rdiff-backup
    rdiff-backup --force --terminal-verbosity 5 --ssh-compression --compression --include-globbing-filelist include-filelist.txt "${BACKUP_ARGS[@]}" "." "$BACKUP_DIRECTORY"
elif [ $BACKUP_METHOD == 'rsync' ]; then
    log "Backing up entire server to $BACKUP_DIRECTORY with rsync..."
    depends rsync
    rsync -avz "${BACKUP_ARGS[@]}" '.' "$BACKUP_DIRECTORY"
else
    log "Backing up entire server to $BACKUP_DIRECTORY with secure copy..."
    depends scp
    scp -Cr "${BACKUP_ARGS[@]}" . $BACKUP_DIRECTORY
fi

log 'Backup completed successfully!'
