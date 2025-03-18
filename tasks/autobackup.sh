#!/bin/bash
# Performs an automatic backup of the entire server to the NAS
# Utilizes backup.sh and stuff.sh to interact with the server as it is running

# Navigate to server root
cd "$(dirname "$0")/.."

# Read server options
. ./env.sh

# Make sure screen is active
if ! sudo -u $RUNAS screen -list | grep -q $SCREEN; then
  echo "Automatic backup skipped as there is no screen $SCREEN running."
  exit 0
fi

# Trap exit to turn automatic saving ON on script exit
trap './stuff.sh save-on; ./stuff.sh "say Server backup complete."' EXIT

echo 'Starting unattended backup...'

# Announce backup start
./stuff.sh 'say Server backup started.'

# Turn automatic saving OFF
./stuff.sh save-off
sleep 1s
./stuff.sh save-all
# Wait for the server to finish saving
echo "Waiting for server save to complete..."
sleep 30s

echo 'Backing up with the backup script...'

# Run backup
./backup.sh || {
  echo 'Backup failed!'
  ./stuff.sh 'say Server backup failed! Please notify the admin.'
}

