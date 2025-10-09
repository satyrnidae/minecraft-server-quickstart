#!/bin/bash
# Launches a Minecraft Forge or Neoforge server.
# Required configuration variables:
#   - JVM:        The command to launch the Java Virtual Machine.
#   - FORGE_ARGS: Set this to the args file from your forge install's default script.
# Exit codes:
#   - 78 (EX_CONFIG): Set if the Java Virtual Machine or the Forge args file could not be located.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'Custom Forge Launch Script v1.0'

command -v "$JVM" >/dev/null 2>&1 || {
    error 'Failed to launch Minecraft Forge server; "'"$JVM"'" not found!'
    fatal $EX_CONFIG 'Please install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.'
}

if ! [ -f "$FORGE_ARGS" ]; then
    error 'Failed to launch Minecraft Forge server; Forge launch args file "'"$FORGE_ARGS"'" could not be found.'
    fatal $EX_CONFIG 'Please ensure your FORGE_ARGS setting in quickstart.env is correct.'
fi

log 'Launching Forge using args from "'"$FORGE_ARGS"'"...'
$JVM -server @user_jvm_args.txt $FORGE_ARGS "$@"
