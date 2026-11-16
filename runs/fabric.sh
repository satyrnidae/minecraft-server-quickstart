#!/bin/bash
# Launches a Fabric Loader server.
# Minecraft versions are resolved against Mojang's version manifest (piston-meta).
# Fabric loader and installer versions are resolved against Fabric's meta API, which also generates the server launcher jar.
# The launcher downloads the vanilla server jar on first run, so no separate server.jar is needed.
# Dependencies:
#	jq	Optional, only used by dynamic mode
#	curl	Optional, only used by dynamic mode
# Required configuration variables:
#	FABRIC_MINECRAFT_VERSION	Set to latest for the latest release, latest-snapshot for the latest snapshot, or an exact version id such as 1.21.4.
#	FABRIC_LOADER_VERSION		Set to latest for the latest stable loader, or an exact loader version such as 0.16.14.
#	FABRIC_INSTALLER_VERSION	Set to latest for the latest stable installer, or an exact installer version such as 1.0.3.
#	JVM				The command to launch the Java Virtual Machine.
# Exit codes:
#	69	EX_UNAVAILABLE	Set if a request to Mojang or Fabric fails to resolve/connect, or returns a non-2xx HTTP response.
#	74	EX_IOERR	Set if the generated launcher jar is somehow missing after the download completes.
#	78	EX_CONFIG	Set if the Java Virtual Machine or a requested version could not be resolved.
#	127	EX_CMDNOTFOUND	Set if jq or curl are not available.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null

# Configure the environment
. ./env.sh

# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'Fabric Server Launch Script v1.0'

depends jq
depends curl

# Resolve the Minecraft version from Mojang's manifest
log 'Pulling version manifest from Mojang.'
case "$FABRIC_MINECRAFT_VERSION" in
latest)
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.release'
	;;
latest-snapshot)
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.snapshot'
	;;
*)
	mc_version="$FABRIC_MINECRAFT_VERSION"
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_check '[.versions[].id] | index("'"$mc_version"'") != null'
	if [[ "$mc_check" != 'true' ]]; then
		error "Failed to resolve Minecraft version \"$mc_version\"; no matching version was found in Mojang's manifest."
		fatal $EX_CONFIG 'Please check the FABRIC_MINECRAFT_VERSION setting in quickstart.env.'
	fi
	;;
esac
log "Minecraft version: $mc_version"

# Resolve the Fabric loader version from Fabric's meta API
if [[ "$FABRIC_LOADER_VERSION" = 'latest' ]]; then
	http_get_json https://meta.fabricmc.net/v2/versions/loader loader_version '[.[] | select(.stable)][0].version'
else
	loader_version="$FABRIC_LOADER_VERSION"
	http_get_json https://meta.fabricmc.net/v2/versions/loader loader_check '[.[].version] | index("'"$loader_version"'") != null'
	if [[ "$loader_check" != 'true' ]]; then
		error "Failed to resolve Fabric loader version \"$loader_version\"; no matching version was found in Fabric's meta API."
		fatal $EX_CONFIG 'Please check the FABRIC_LOADER_VERSION setting in quickstart.env.'
	fi
fi
log "Fabric loader version: $loader_version"

# Resolve the Fabric installer version from Fabric's meta API
if [[ "$FABRIC_INSTALLER_VERSION" = 'latest' ]]; then
	http_get_json https://meta.fabricmc.net/v2/versions/installer installer_version '[.[] | select(.stable)][0].version'
else
	installer_version="$FABRIC_INSTALLER_VERSION"
	http_get_json https://meta.fabricmc.net/v2/versions/installer installer_check '[.[].version] | index("'"$installer_version"'") != null'
	if [[ "$installer_check" != 'true' ]]; then
		error "Failed to resolve Fabric installer version \"$installer_version\"; no matching version was found in Fabric's meta API."
		fatal $EX_CONFIG 'Please check the FABRIC_INSTALLER_VERSION setting in quickstart.env.'
	fi
fi
log "Fabric installer version: $installer_version"

# Download the server launcher jar for this combination
filename="fabric-server-mc.$mc_version-loader.$loader_version-launcher.$installer_version.jar"
download_url="https://meta.fabricmc.net/v2/versions/loader/$mc_version/$loader_version/$installer_version/server/jar"

log "Downloading $filename from $download_url..."
rm -f "$filename" >/dev/null
http_get_file "$download_url" "$filename"

if ! [ -s "$filename" ]; then
	error "Failed to download the Fabric server launcher jar \"$filename\"."
	fatal $EX_IOERR 'Failed to download the Fabric server launcher jar from the Fabric meta API.'
fi

echo "Downloaded Fabric $loader_version for Minecraft $mc_version!"

line_feed

command -v "$JVM" >/dev/null 2>&1 || {
	error 'Failed to launch Fabric server; "'"$JVM"'" not found!'
	fatal $EX_CONFIG 'Please install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.'
}

log 'Launching the Fabric server jar "'"$filename"'" with the options from user_jvm_args.txt and the args "'"$@"'"...'

trap 'fatal '"$EX_SIGINT"' "User sent SIGINT (Ctrl+C). Exiting."' INT
$JVM -server @user_jvm_args.txt -jar "$filename" "$@"
trap - INT
