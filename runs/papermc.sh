#!/bin/bash
# Launches a PaperMC server.
# This script also uses the PaperMC.io API to optionally download a dynamic release number from the PaperMC website.
# Dependencies:
#   - jq   (Optional)
#   - curl (Optional)
# Required configuration variables:
#   - PAPERCRAFT_JAR:     Set this to dynamic to download the latest build from Papers API, or set to a specific jar file.
#   - PAPERCRAFT_VERSION: If PAPERCRAFT_JAR is set to dynamic, this will determine which Minecraft version is downloaded. Set to latest to use the latest version.
#   - JVM:                The command to launch the Java Virtual Machine.
# Exit codes:
#   - 74  (EX_IOERR):       Set if the dynamically downloaded server file is somehow missing after the download completes.
#   - 78  (EX_CONFIG):      Set if the Java Virtual Machine or the server jar file could not be located.
#   - 127 (EX_CMDNOTFOUND): Set if dynamic jar download is enabled and either jq or curl are not available.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'Papercraft Shell Server Updater and Launcher v2.1'

if [[ "$PAPERCRAFT_JAR" = 'dynamic' ]]; then
    depends rdiff-backup

    depends jq
    depends curl

    # Get the latest version and build from
    if [[ "$PAPERCRAFT_VERSION" = "latest" ]]; then
        log 'Pulling latest minecraft version from papermc.io.'
        latest_version=$( curl -s -X GET \
                          -H 'accept: application/json' \
                          https://api.papermc.io/v2/projects/paper \
                          | jq -r '.versions[-1]' )
        log "Launching Minecraft v$latest_version!"
    else
        log "Pulling latest $PAPERCRAFT_VERSION build from papermc.io."
        latest_version=$PAPERCRAFT_VERSION
    fi
    latest_build=$( curl -s -X GET \
                    -H 'accept: application/json' \
                    https://api.papermc.io/v2/projects/paper/versions/$latest_version \
                    | jq -r '.builds[-1]' )
    application=$( curl -s -X GET \
                   -H 'accept: application/json' \
                   https://api.papermc.io/v2/projects/paper/versions/$latest_version/builds/$latest_build \
                   | jq -r '.downloads.application')
    filename=$( echo $application | jq -r '.name')
    sha256=$( echo $application | jq -r '.sha256')
    exists_sha256=""

    log "PaperMC Latest Version: $filename"

    if [ -f "$filename" ]; then
        log 'Checking SHA256 sum of existing file...'
        exists_sha256=$( sha256sum "$filename" | cut -d ' ' -f 1 )
        log "Expected: $sha256"
        log "Got:      $exists_sha256"
    fi

    log 'Verifying checksum...'

    while ! [[ "$sha256" = "$exists_sha256" ]]; do
        log 'Checksum mismatch:'
        log "  Expected: $sha256"
        log "  Got:      $exists_sha256"
        log 'Removing any existing file and retrying download...'
        rm -f $filename >/dev/null
        download_url="https://api.papermc.io/v2/projects/paper/versions/$latest_version/builds/$latest_build/downloads/$filename"
        log "Downloading from $download_url..."
        curl -X 'GET' \
            $download_url \
            -H 'accept: application/json' \
            --output $filename
        log 'Download complete. Verifying new checksum...'
        exists_sha256=$( sha256sum $filename | cut -d ' ' -f 1 )
    done

    echo "Verified PaperMC $latest_version.$latest_build!"
fi

line_feed

command -v "$JVM" >/dev/null 2>&1 || {
    error 'Failed to launch PaperMC; "'"$JVM"'" was not found!'
    fatal $EX_CONFIG 'Please ensure your JVM is set correctly in quickstart.env.'
}

if ! [ -f "$filename" ]; then
    error 'Failed to launch PaperMC; server jar file "'"$filename"'" not found!'
    if [[ "$PAPERCRAFT_JAR" = 'dynamic' ]]; then
        fatal $EX_IOERR 'Failed to download server jar file from papermc.io.'
    else
        fatal $EX_CONFIG 'Please ensure that your PAPERCRAFT_JAR setting in quickstart.env is correct.'
    fi
fi

log 'Launching the server jar "'"$filename"'" with the options from user_jvm_args.txt...'

$JVM -server @user_jvm_args.txt -jar $filename "$@"
