#!/bin/bash
# Launches a vanilla Minecraft server.
# This script also uses Mojang's version manifest API to optionally download a specific server jar by version.
# Dependencies:
#   - jq   (Optional)
#   - curl (Optional)
# Required configuration variables:
#   - MINECRAFT_JAR:     Set this to dynamic to download a server jar from Mojang's API, or set to a specific jar file.
#   - MINECRAFT_VERSION: If MINECRAFT_JAR is set to dynamic, this will determine which Minecraft version is downloaded. Set to latest for the latest release, latest-snapshot for the latest snapshot, or an exact version id such as 1.20.4.
#   - JVM:               The command to launch the Java Virtual Machine.
# Exit codes:
#   - 69  (EX_UNAVAILABLE): Set if a request to Mojang's API fails to resolve/connect, or returns a non-2xx HTTP response.
#   - 74  (EX_IOERR):       Set if the dynamically downloaded server file is somehow missing after the download completes.
#   - 78  (EX_CONFIG):      Set if the Java Virtual Machine, the requested version, or the server jar file could not be located.
#   - 127 (EX_CMDNOTFOUND): Set if dynamic jar download is enabled and either jq or curl are not available.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null
# Configure the environment
. ./env.sh
# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'Minecraft Server Launch Script v2.0'

filename="$MINECRAFT_JAR"

if [[ "$MINECRAFT_JAR" = 'dynamic' ]]; then
    depends jq
    depends curl

    log 'Pulling version manifest from Mojang.'
    http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json manifest

    case "$MINECRAFT_VERSION" in
        latest)
            version=$( echo $manifest | jq -r '.latest.release' )
            ;;
        latest-snapshot)
            version=$( echo $manifest | jq -r '.latest.snapshot' )
            ;;
        *)
            version="$MINECRAFT_VERSION"
            ;;
    esac

    log "Resolving Minecraft version $version..."

    version_url=$( echo $manifest | jq -r --arg v "$version" '.versions[] | select(.id == $v) | .url' )

    if [[ -z "$version_url" || "$version_url" = 'null' ]]; then
        error "Failed to resolve Minecraft version \"$version\"; no matching version was found in Mojang's manifest."
        log "Versions available: $( echo $manifest | jq -r '[.versions[].id] | join(", ")' )"
        fatal $EX_CONFIG 'Please check the MINECRAFT_VERSION setting in quickstart.env.'
    fi

    http_get_json $version_url version_meta
    download_url=$( echo $version_meta | jq -r '.downloads.server.url' )
    sha1=$( echo $version_meta | jq -r '.downloads.server.sha1' )

    if [[ -z "$download_url" || "$download_url" = 'null' ]]; then
        fatal $EX_CONFIG "Mojang does not provide a server.jar version for v$version. Please choose another MINECRAFT_VERSION."
    fi

    filename="server-$version.jar"
    exists_sha1=""

    log "Minecraft $version server jar: $filename"

    if [ -f "$filename" ]; then
        log 'Checking SHA1 sum of existing file...'
        exists_sha1=$( sha1sum "$filename" | cut -d ' ' -f 1 )
        log "Expected: $sha1"
        log "Got:      $exists_sha1"
    fi

    log 'Verifying checksum...'

    while ! [[ "$sha1" = "$exists_sha1" ]]; do
        log 'Checksum mismatch:'
        log "  Expected: $sha1"
        log "  Got:      $exists_sha1"
        log 'Removing any existing file and retrying download...'
        rm -f $filename >/dev/null
        log "Downloading from $download_url..."
        http_get_file $download_url $filename
        log 'Download complete. Verifying new checksum...'
        exists_sha1=$( sha1sum $filename | cut -d ' ' -f 1 )
    done

    echo "Verified Minecraft $version server jar!"
fi

line_feed

command -v "$JVM" >/dev/null 2>&1 || {
    error 'Failed to launch Minecraft server; "'"$JVM"'" not found!'
    fatal $EX_CONFIG 'Please install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.'
}

if ! [ -f "$filename" ]; then
    error 'Failed to launch the Minecraft server; the server jar file "'"$filename"'" could not be located.'
    if [[ "$MINECRAFT_JAR" = 'dynamic' ]]; then
        fatal $EX_IOERR 'Failed to download server jar file from Mojang.'
    else
        fatal $EX_CONFIG 'Please ensure that your MINECRAFT_JAR setting in quickstart.env is correct.'
    fi
fi

log 'Launching the server jar "'"$filename"'" with the options from user_jvm_args.txt and the args "'"$@"'"...'

trap 'fatal '"$EX_SIGINT"' "User sent SIGINT (Ctrl+C). Exiting."' INT
$JVM -server @user_jvm_args.txt -jar $filename "$@"
trap - INT
