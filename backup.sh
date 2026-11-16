#!/bin/bash
# Backs up the server to the BACKUP_DIRECTORY using BACKUP_METHOD
# Dependencies:
#	duplicity
#	ssh, sftp, scp, rsync	Optional, duplicity only, checked per target URL scheme. ssh, sftp and scp are only checked when BACKUP_ARGS has --ssh-backend pexpect.)
#	rdiff-backup		Optional
#	rsync			Optional
#	scp			Optional
# Configuration variables:
#	BACKUP_METHOD				Select one BACKUP_METHOD from the provided options in quickstart.env
#	BACKUP_DIRECTORY			Destination folder for backups. If using rsync or rdiff201, change this to use a folder outside the current directory.
#						With duplicity, a plain path is resolved to an absolute file:// URL; any other URL scheme is passed through untouched.
#	BACKUP_ARGS				Extra args for the backup command as a bash array. With duplicity this is where --full-if-older-than lives.
#	BACKUP_DUPLICITY_AUTOREMOVE		Set to true to prune old chains after a successful duplicity backup.
#	BACKUP_DUPLICITY_AUTOREMOVE_CNT		Number of full chains to keep, newest first. Must be 1 or more.
#	BACKUP_DUPLICITY_AUTOREMOVE_ARGS	Extra args for the remove-all-but-n-full command as a bash array. --force is always sent, as it is needed to delete anything.
# Exit codes:
#	127	EX_CMDNOTFOUND	Your selected backup method was not executable and/or available on the PATH.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

if [ "$BACKUP_METHOD" == 'duplicity' ]; then
	depends duplicity
	# duplicity wants a URL target. Resolve plain paths against the server directory.
	duplicity_target="$BACKUP_DIRECTORY"
	if [[ "$duplicity_target" != *://* ]]; then
		duplicity_target="file://$(realpath -m "$duplicity_target")"
	fi
	# Only the pexpect ssh backend shells out to the system clients, and only when BACKUP_ARGS names it
	duplicity_pexpect=false
	for ((i = 0; i < ${#BACKUP_ARGS[@]}; i++)); do
		if [ "${BACKUP_ARGS[$i]}" == '--ssh-backend=pexpect' ] || { [ "${BACKUP_ARGS[$i]}" == '--ssh-backend' ] && [ "${BACKUP_ARGS[$((i + 1))]}" == 'pexpect' ]; }; then
			duplicity_pexpect=true
		fi
	done
	case "$duplicity_target" in
		sftp://*|ssh://*)
			if [ "$duplicity_pexpect" == 'true' ]; then
				depends ssh
				depends sftp
			fi
			;;
		scp://*)
			if [ "$duplicity_pexpect" == 'true' ]; then
				depends ssh
				depends scp
			fi
			;;
		rsync://*)
			# rsync:// has its own backend, which always runs rsync over the system ssh
			depends rsync
			depends ssh
			;;
	esac
	log "Backing up entire server to $duplicity_target with duplicity, w/ excludes."
	# incremental promotes itself to a full when no chain exists or --full-if-older-than trips
	duplicity incremental --include-filelist include-filelist.txt "${BACKUP_ARGS[@]}" . "$duplicity_target"
	backup_exit=$?
	if [ $backup_exit -eq 0 ] && [ "$BACKUP_DUPLICITY_AUTOREMOVE" == 'true' ]; then
		log "Removing all but the newest $BACKUP_DUPLICITY_AUTOREMOVE_CNT full backup chains from $duplicity_target."
		duplicity remove-all-but-n-full "$BACKUP_DUPLICITY_AUTOREMOVE_CNT" --force "${BACKUP_DUPLICITY_AUTOREMOVE_ARGS[@]}" "$duplicity_target"
		backup_exit=$?
		if [ $backup_exit -ne 0 ]; then
			error "Backup succeeded, but removing old chains exited with status $backup_exit."
		fi
	fi
elif [ $BACKUP_METHOD == 'rdiff201' ]; then
	log "Backing up entire server to $BACKUP_DIRECTORY with rdiff-backup, new CLI."
	depends rdiff-backup
	rdiff-backup --force --api-version 201 --terminal-verbosity 5 --ssh-compression backup "${BACKUP_ARGS[@]}" . $BACKUP_DIRECTORY
	backup_exit=$?
elif [ $BACKUP_METHOD == 'rdiff' ]; then
	log "Backing up entire server to $BACKUP_DIRECTORY with rdiff-backup, legacy CLI w/ excludes."
	depends rdiff-backup
	rdiff-backup --force --terminal-verbosity 5 --ssh-compression --compression --include-globbing-filelist include-filelist.txt "${BACKUP_ARGS[@]}" "." "$BACKUP_DIRECTORY"
	backup_exit=$?
elif [ $BACKUP_METHOD == 'rsync' ]; then
	log "Backing up entire server to $BACKUP_DIRECTORY with rsync..."
	depends rsync
	rsync -avz "${BACKUP_ARGS[@]}" '.' "$BACKUP_DIRECTORY"
	backup_exit=$?
else
	log "Backing up entire server to $BACKUP_DIRECTORY with secure copy..."
	depends scp
	scp -Cr "${BACKUP_ARGS[@]}" . $BACKUP_DIRECTORY
	backup_exit=$?
fi

if [ $backup_exit -ne 0 ]; then
	fatal $backup_exit "Backup command exited with status $backup_exit."
fi

log 'Backup completed successfully!'
