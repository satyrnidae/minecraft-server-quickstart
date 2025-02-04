#!/bin/bash
# Loads launcher properties into environment variables, and creates a default env file if none exists.
cd "$(dirname "$0")"

properties_file='./quickstart.env'

# Initialize the properties file if it doesn't yet exist.
if [ ! -f $properties_file ]; then
    touch $properties_file
    echo '# This file defines the environment variables available to scripts which source env.sh.' > $properties_file
    echo '# Environment variables cannot contain spaces or periods in their names.' >> $properties_file
    echo '# You may define your own environment variables at the top of this file.' >> $properties_file
    echo ''                                 >> $properties_file
    echo '# Add your custom environment variables here.' >> $properties_file
    echo ''                                 >> $properties_file
    echo '##### DO NOT DELETE ENTRIES BELOW THIS LINE #####' >> $properties_file
    echo ''                                 >> $properties_file
    echo '# Common environment variables'   >> $properties_file
    echo 'SCREEN=minecraft_server'          >> $properties_file
    echo "RUNAS=$(whoami)"                  >> $properties_file
    echo ''                                 >> $properties_file
    echo '# start.sh options'               >> $properties_file
    echo 'LAUNCH_CMD="./run.sh"'            >> $properties_file
    echo ''                                 >> $properties_file
    echo '# run.sh options'                 >> $properties_file
    echo 'RUN_SCRIPT=papermc.sh'            >> $properties_file
    echo 'RUN_SCRIPT_ARGS=--nogui'          >> $properties_file
    echo 'RESTART_WAIT_TIME=10s'            >> $properties_file
    echo "JVM=$(which java || echo "java")" >> $properties_file
    echo ''                                 >> $properties_file
    echo '# run.sh.d/papermc.sh options'    >> $properties_file
    echo 'PAPERCRAFT_JAR=dynamic    # Set this to dynamic to download the latest build from Paper''s API, or set to a specific jar file.' >> $properties_file
    echo 'PAPERCRAFT_VERSION=latest # If PAPERCRAFT_JAR is set to dynamic, this will determine which Minecraft version is downloaded. Set to latest to use the latest version.' >> $properties_file
    echo ''                                 >> $properties_file
    echo '# run.sh.d/forge.sh options'      >> $properties_file
    echo 'FORGE_JAR=@libraries/net/minecraftforge/forge/1.19.2-43.4.16/unix_args.txt # Set this to the args file or server jar from your forge install''s default script.' >> $properties_file
    echo ''                                 >> $properties_file
    echo '# backup.sh options'              >> $properties_file
    echo 'BACKUP_DIRECTORY=backups/ # Used to perform a full folder rdiff backup. Include and exclude files by editing backup.sh.d/include-filelist.txt' >> $properties_file

fi

# echo "$(grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' $properties_file | sed -E 's/(.+?)=(.*)/\U\1\E=\2/;' | xargs -d '\n' -0 -l1)"
set -a
. $properties_file
set +a