#!/bin/bash
# Utilizes rdiff-backup to backup the server files.
cd "$(dirname "$0")"

# Read server options
. ./env.sh

if [ $BACKUP_METHOD == 'rdiff201' ]; then
    echo "Backing up entire server to $BACKUP_DIRECTORY with rdiff-backup, new CLI..."
    which rdiff-backup &>/dev/null || {
        printf 'Failed to start backup; rdiff-backup was not found!\nPlease install rdiff-backup and ensure it is on your PATH.\n' &>2
        exit 127
    }
    rdiff-backup --force --api-version 201 --terminal-verbosity 5 --ssh-compression backup . $BACKUP_DIRECTORY
elif [ $BACKUP_METHOD == 'rdiff']; then
    echo "Backing up entire server to ${BACKUP_DIRECTORY} with rdiff-backup, legacy CLI w/ excludes..."
    which rdiff-backup &>/dev/null || {
        printf 'Failed to start backup; rdiff-backup was not found!\nPlease install rdiff-backup and ensure it is on your PATH.\n' &>2
        exit 127
    }
    rdiff-backup --force --terminal-verbosity 5 --ssh-compression --compression --include-globbing-filelist include-filelist.txt "." "${BACKUP_DIRECTORY}"
elif [ $BACKUP_METHOD == 'rsync' ]; then
    echo "Backing up entire server to ${BACKUP_DIRECTORY} with rsync..."
    which rsync &>/dev/null || {
        printf 'Failed to start backup; rsync was not found!\nPlease install rsync and ensure it is on your PATH.\n' &>2
        exit 127
    }
    rsync -avz "." "${BACKUP_DIRECTORY}"
else
    echo "Backing up entire server to ${BACKUP_DIRECTORY} with secure copy..."
    which scp &>/dev/null || {
        printf 'Failed to start backup; secure copy was not found!\nPlease install OpenSSL and ensure it is on your PATH.\n'
        exit 127
    }
    scp -Cr . $BACKUP_DIRECTORY
fi

echo 'Backup completed successfully!'
