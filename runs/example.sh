#!/bin/bash
# This is an example script for launching a minecraft JAR file.
# Feel free to modify this to your purposes.
# Required configuration variables:
#   - JVM: The command to launch the Java Virtual Machine.
#   - EXAMPLE_SCRIPT_JARFILE: The name of the jar file to launch.
# Exit codes:
#   - 78 (EX_CONFIG): Set if the Java Virtual Machine or the Minecraft server jar could not be located.

# This section is needed to execute the env.sh script. Without it we wouldn't have access to the prepend_trap, log, error, and fatal functions.
# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'Minecraft Server Launch Script v1.0'

command -v "$JVM" >/dev/null 2>&1 || {
    error 'Failed to launch Minecraft server; "'"$JVM"'" not found!'
    # EX_CONFIG is a special error code; if the script exits with this code, the run.sh script will halt without attempting a restart.
    fatal $EX_CONFIG 'Please install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.'
}

if ! [ -f "$EXAMPLE_SCRIPT_JARFILE" ]; then
    error 'Failed to launch the Minecraft server; the server jar file "'"$EXAMPLE_SCRIPT_JARFILE"'" could not be located.'
    fatal $EX_CONFIG 'Please ensure that your EXAMPLE_SCRIPT_JARFILE setting in quickstart.env is correct.'
fi

log 'Launching Minecraft server jar "'"$EXAMPLE_SCRIPT_JARFILE"'"...'
$JVM -server @user_jvm_args.txt -jar $EXAMPLE_SCRIPT_JARFILE "$@"
