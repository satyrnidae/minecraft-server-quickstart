#!/bin/bash
echo "Custom Forge Launch Script v1.0"

which $JVM &>/dev/null || {
    printf '\nFailed to launch Minecraft server; $JVM not found!\nPlease install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.\n'
    exit 127
}

printf '\nLaunching server file %s...\n' "${FORGE_ARGS}"
$JVM -server @user_jvm_args.txt $FORGE_ARGS "$@"
