#!/bin/bash
# Backs up the server to the BACKUP_DIRECTORY using BACKUP_METHOD
# Dependencies:
#	duplicity
#	ssh, sftp, scp, rsync	Optional, duplicity only, checked per target URL scheme. ssh, sftp and scp are only checked when BACKUP_ARGS has --ssh-backend pexpect. ssh is always checked for remote targets, as creating the remote directory runs mkdir --parents over it.
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
#	73	EX_CANTCREAT	Failed to create backup directory for Duplicity
#	127	EX_CMDNOTFOUND	Your selected backup method was not executable and/or available on the PATH.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")" >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

# Splits a remote duplicity URL into REMOTE_USER, REMOTE_HOST, REMOTE_PORT and REMOTE_PATH.
# One slash after the host is relative to the remote home, two is absolute. Passwords in the URL are dropped.
parse_remote_url() {
	local rest=${1#*://} auth
	auth=${rest%%/*}
	REMOTE_PATH=''
	[[ "$rest" == */* ]] && REMOTE_PATH=${rest#*/}
	REMOTE_USER=''
	if [[ "$auth" == *@* ]]; then
		REMOTE_USER=${auth%%@*}
		REMOTE_USER=${REMOTE_USER%%:*}
	fi
	REMOTE_HOST=${auth##*@}
	REMOTE_PORT=''
	if [[ "$REMOTE_HOST" == *:* ]]; then
		REMOTE_PORT=${REMOTE_HOST##*:}
		REMOTE_HOST=${REMOTE_HOST%:*}
	fi
}

# Creates a remote backup directory and any missing parents with mkdir --parents over ssh.
# Needs a login shell and GNU mkdir on the remote, and key auth, as prompts are disabled.
# BACKUP_ARGS such as --ssh-options are not applied here, only the port from the URL.
make_remote_dir() {
	local url=$1 dest quoted
	parse_remote_url "$url"
	[ -z "$REMOTE_PATH" ] && return 0
	if [[ "$url" == rsync://*::* ]]; then
		warning 'Skipping remote directory creation for an rsync daemon target.'
		return 0
	fi
	depends ssh
	dest=$REMOTE_HOST
	[ -n "$REMOTE_USER" ] && dest="$REMOTE_USER@$REMOTE_HOST"
	# Single quote the path for the remote shell, escaping any single quotes inside it
	quoted=${REMOTE_PATH//\'/\'\\\'\'}
	ssh ${REMOTE_PORT:+-p "$REMOTE_PORT"} -o BatchMode=yes "$dest" "mkdir --parents -- '$quoted'"
}

if [ "$BACKUP_METHOD" == 'duplicity' ]; then
	depends duplicity
	# duplicity wants a URL target. Resolve plain paths against the server directory.
	duplicity_target="$BACKUP_DIRECTORY"
	if [[ "$duplicity_target" != *://* ]]; then
		duplicity_target="file://$(realpath -m "$duplicity_target")"
	fi
	# Local targets get created up front, so a fresh drive or folder does not depend on the backend doing it
	if [[ "$duplicity_target" == file://* ]]; then
		mkdir -p "${duplicity_target#file://}" || fatal $EX_CANTCREAT "Could not create backup directory ${duplicity_target#file://}."
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
	# Remote targets get their directory made over the wire
	case "$duplicity_target" in
		sftp://*|ssh://*|scp://*|rsync://*)
			make_remote_dir "$duplicity_target" || fatal $EX_CANTCREAT "Could not create remote backup directory $duplicity_target."
			;;
	esac
	# Encryption: a GnuPG key or passphrase if configured, otherwise none, so unattended runs never prompt
	if [ -n "${BACKUP_ENCRYPT_KEY:-}" ]; then
		duplicity_enc_args=(--encrypt-key "$BACKUP_ENCRYPT_KEY")
	elif [ -n "${PASSPHRASE:-}" ]; then
		duplicity_enc_args=()
	else
		duplicity_enc_args=(--no-encryption)
	fi
	# A passphrase may also unlock the key, so export it either way
	if [ -n "${PASSPHRASE:-}" ]; then
		export PASSPHRASE
	fi
	log "Backing up entire server to $duplicity_target with duplicity, w/ excludes."
	# incremental promotes itself to a full when no chain exists or --full-if-older-than trips
	# Global options must come before the action, or duplicity counts them as positional args
	duplicity "${BACKUP_ARGS[@]}" "${duplicity_enc_args[@]}" incremental --include-filelist include-filelist.txt . "$duplicity_target"
	backup_exit=$?
	if [ $backup_exit -eq 0 ] && [ "$BACKUP_DUPLICITY_AUTOREMOVE" == 'true' ]; then
		log "Removing all but the newest $BACKUP_DUPLICITY_AUTOREMOVE_CNT full backup chains from $duplicity_target."
		duplicity "${BACKUP_DUPLICITY_AUTOREMOVE_ARGS[@]}" "${duplicity_enc_args[@]}" --force remove-all-but-n-full "$BACKUP_DUPLICITY_AUTOREMOVE_CNT" "$duplicity_target"
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
