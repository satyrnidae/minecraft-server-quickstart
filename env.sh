#!/bin/bash
# Loads launcher properties into environment variables, and creates a default env file if none exists.

properties_file='./quickstart.env'

# Initialize the properties file if it doesn't yet exist.
if [ ! -f $properties_file ]; then
    touch $properties_file
    echo '# This file defines the environment variables available to scripts which source env.sh.' > $properties_file
    echo '# Environment variables cannot contain spaces or periods in their names.' >> $properties_file
    echo '# You may define your own environment variables at the top of this file.' >> $properties_file
    echo '' >> $properties_file
    echo '# Add your custom environment variables here.' >> $properties_file
    echo '' >> $properties_file
    echo '##### DO NOT DELETE ENTRIES BELOW THIS LINE #####' >> $properties_file
    echo '' >> $properties_file
    echo '# Common environment variables' >> $properties_file
    echo 'SCREEN=minecraft_server' >> $properties_file
    echo "RUNAS=$(whoami)" >> $properties_file
    echo '' >> $properties_file
    echo '# start.sh options' >> $properties_file
    echo 'LAUNCH_CMD="./run.sh"' >> $properties_file
    echo '' >> $properties_file
    echo '# run.sh options' >> $properties_file
    echo 'RUN_SCRIPT=papermc      # Must match the filename of a script in the runs/ folder, sans extension' >> $properties_file
    echo 'RUN_SCRIPT_ARGS=--nogui # These arguments are passed directly to the script file by run.sh' >> $properties_file
    echo 'RESTART_WAIT_TIME=10s' >> $properties_file
    echo '' >> $properties_file
    echo '# Common arguments for all runs/ scripts' >> $properties_file
    echo "JVM='$(realpath "$(which java)" || echo java)'" >> $properties_file
    echo '' >> $properties_file
    echo '# runs/papermc.sh options' >> $properties_file
    echo 'PAPERCRAFT_JAR=dynamic    # Set this to dynamic to download the latest build from Paper''s API, or set to a specific jar file.' >> $properties_file
    echo 'PAPERCRAFT_VERSION=latest # If PAPERCRAFT_JAR is set to dynamic, this will determine which Minecraft version is downloaded. Set to latest to use the latest version.' >> $properties_file
    echo '' >> $properties_file
    echo '# runs/forge.sh options' >> $properties_file
    echo 'FORGE_ARGS=@libraries/net/minecraftforge/forge/1.19.2-43.4.16/unix_args.txt # Set this to the args file from your forge install''s default script.' >> $properties_file
    echo '' >> $properties_file
    echo '# runs/minecraft.sh options' >> $properties_file
    echo 'SERVER_JAR=server.jar # Set this to the name of the jar file you want to run.' >> $properties_file
    echo '' >> $properties_file
    echo '# backup.sh options' >> $properties_file
    echo '# Select one BACKUP_METHOD from the options below.' >> $properties_file
    echo 'BACKUP_METHOD=rdiff       # Legacy rdiff-backup CLI. Uses include-filelist.txt to designate included and excluded files and folders. Only enable if your rdiff-backup install supports the deprecated pre-201 CLI.' >> $properties_file
    echo '#BACKUP_METHOD=rdiff201   # New rdiff-backup CLI. Use an external or network folder for BACKUP_DIRECTORY, as include-filelist is no longer used.' >> $properties_file
    echo '#BACKUP_METHOD=rsync      # Use rsync instead of rdiff-backup. Use an external or network folder for BACKUP_DIRECTORY, as no files are excluded.' >> $properties_file
    echo '#BACKUP_METHOD=scp        # Use secure copy for the backup. Use an external or network folder for BACKUP_DIRECTORY, as no files will be excluded.' >> $properties_file
    echo 'BACKUP_DIRECTORY=backups/ # Destination folder for backups. If using rsync or rdiff201, use a folder outside the current directory.' >> $properties_file
    echo '' >> $properties_file
    echo '# autorestart.sh / autoreboot.sh task properties' >> $properties_file
    echo 'KICK_CMD="kick @a \"The server is restarting! We'"'"'ll be back in a bit!\""' >> $properties_file
    echo '' >> $properties_file
    echo '# watchdog.sh task properties' >> $properties_file
    echo "MCLI='$(realpath "$(which mcli)" || echo mcli)'" >> $properties_file
    echo 'ENABLE_QUERY=1    # Set to 0 to disable touch of the .watchdog_lock file' >> $properties_file
    echo 'QUERY_PORT=25567' >> $properties_file
    echo 'QUERY_TIMEOUT=300 # The time, in seconds, to wait for the query result. May need to be adjusted if the startup time for your server is very long.' >> $properties_file
fi

set -a
. $properties_file
set +a
