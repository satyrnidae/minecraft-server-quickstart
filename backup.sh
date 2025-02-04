#!/bin/bash
# Utilizes rdiff-backup to backup the server files.
cd "$(dirname "$0")"

# Read server options
. ./env.sh

which rdiff-backup &>/dev/null || {
    printf 'Failed to start backup; rdiff-backup was not found!\nPlease install rdiff-backup and ensure it is on your PATH.'
    exit 127
}

echo 'Backing up to the NAS with rdiff...'

# rdiff-backup --force --api-version 201 --terminal-verbosity 5 backup . $BACKUP_DIRECTORY
rdiff-backup --force --terminal-verbosity 5 --include-globbing-filelist backup.sh.d/include-filelist.txt "." "$BACKUP_DIRECTORY"

echo 'Done!'
