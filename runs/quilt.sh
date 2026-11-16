#!/bin/bash
# Launches a Quilt Loader server.
# Minecraft versions are resolved against Mojang's version manifest (piston-meta).
# Loader and installer versions are resolved against Quilt's meta API.
# Quilt's meta API does not provide a server jar, so the Quilt installer is run in server mode to install the server and download the vanilla server jar.
# Dependencies:
#	jq	Optional, only used by dynamic mode
#	curl	Optional, only used by dynamic mode
#	java	Required to run the Quilt installer
# Required configuration variables:
#	QUILT_MINECRAFT_VERSION	Set to latest for the latest release, latest-snapshot for the latest snapshot, or an exact version id such as 1.21.1.
#	QUILT_LOADER_VERSION	Set to latest for the latest non-beta loader, or an exact loader version such as 0.20.0-beta.9.
#	QUILT_INSTALLER_VERSION	Set to latest for the latest installer, or an exact installer version such as 0.15.1.
#	JVM			The command to launch the Java Virtual Machine.
# Exit codes:
#	69	EX_UNAVAILABLE	Set if a request to Mojang or Quilt fails to resolve/connect, or returns a non-2xx HTTP response.
#	74	EX_IOERR	Set if the Quilt installer or the server launch jar is missing after the install step.
#	78	EX_CONFIG	Set if the Java Virtual Machine or a requested version could not be resolved.
#	127	EX_CMDNOTFOUND	Set if jq or curl are not available.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null

# Configure the environment
. ./env.sh

# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'Quilt Server Launch Script v1.0'

depends jq
depends curl

# Resolve the Minecraft version from Mojang's manifest
log 'Pulling version manifest from Mojang.'
case "$QUILT_MINECRAFT_VERSION" in
latest)
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.release'
	;;
latest-snapshot)
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.snapshot'
	;;
*)
	mc_version="$QUILT_MINECRAFT_VERSION"
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_check '[.versions[].id] | index("'"$mc_version"'") != null'
	if [[ "$mc_check" != 'true' ]]; then
		error "Failed to resolve Minecraft version \"$mc_version\"; no matching version was found in Mojang's manifest."
		fatal $EX_CONFIG 'Please check the QUILT_MINECRAFT_VERSION setting in quickstart.env.'
	fi
	;;
esac
log "Minecraft version: $mc_version"

# Resolve the Quilt loader version from Quilt's meta API, preferring non-beta releases for latest
if [[ "$QUILT_LOADER_VERSION" = 'latest' ]]; then
	http_get_json https://meta.quiltmc.org/v3/versions/loader loader_version '([.[] | select(.version | contains("-") | not)][0] // .[0]).version'
else
	loader_version="$QUILT_LOADER_VERSION"
	http_get_json https://meta.quiltmc.org/v3/versions/loader loader_check '[.[].version] | index("'"$loader_version"'") != null'
	if [[ "$loader_check" != 'true' ]]; then
		error "Failed to resolve Quilt loader version \"$loader_version\"; no matching version was found in Quilt's meta API."
		fatal $EX_CONFIG 'Please check the QUILT_LOADER_VERSION setting in quickstart.env.'
	fi
fi
log "Quilt loader version: $loader_version"

# Resolve the Quilt installer version from Quilt's meta API
if [[ "$QUILT_INSTALLER_VERSION" = 'latest' ]]; then
	http_get_json https://meta.quiltmc.org/v3/versions/installer installer_version '.[0].version'
else
	installer_version="$QUILT_INSTALLER_VERSION"
	http_get_json https://meta.quiltmc.org/v3/versions/installer installer_check '[.[].version] | index("'"$installer_version"'") != null'
	if [[ "$installer_check" != 'true' ]]; then
		error "Failed to resolve Quilt installer version \"$installer_version\"; no matching version was found in Quilt's meta API."
		fatal $EX_CONFIG 'Please check the QUILT_INSTALLER_VERSION setting in quickstart.env.'
	fi
fi
log "Quilt installer version: $installer_version"

# Download the installer for this version, if it is not already present
installer_jar="quilt-installer-$installer_version.jar"
installer_url="https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/$installer_version/quilt-installer-$installer_version.jar"

if ! [ -s "$installer_jar" ]; then
	log "Downloading $installer_jar from $installer_url..."
	rm -f "$installer_jar" >/dev/null
	http_get_file "$installer_url" "$installer_jar"
fi

if ! [ -s "$installer_jar" ]; then
	error "Failed to download the Quilt installer \"$installer_jar\"."
	fatal $EX_IOERR 'Failed to download the Quilt installer from the Quilt maven repository.'
fi

# Run the installer in server mode; this downloads the vanilla server jar and writes quilt-server-launch.jar to the current directory
command -v "$JVM" >/dev/null 2>&1 || {
	error 'Failed to install Quilt server; "'"$JVM"'" not found!'
	fatal $EX_CONFIG 'Please install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.'
}

log "Installing Quilt $loader_version for Minecraft $mc_version..."
$JVM -jar "$installer_jar" install server "$mc_version" "$loader_version" --download-server --install-dir=. || {
	fatal $EX_IOERR 'The Quilt installer failed. See its output above.'
}

filename='quilt-server-launch.jar'
if ! [ -f "$filename" ]; then
	error "Failed to launch Quilt server; the launch jar \"$filename\" was not produced by the installer."
	fatal $EX_IOERR 'Please check the installer output above.'
fi

line_feed

log 'Launching the Quilt server jar "'"$filename"'" with the options from user_jvm_args.txt and the args "'"$@"'"...'

trap 'fatal '"$EX_SIGINT"' "User sent SIGINT (Ctrl+C). Exiting."' INT
$JVM -server @user_jvm_args.txt -jar "$filename" "$@"
trap - INT
