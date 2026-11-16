#!/bin/bash
# Launches a NeoForge server.
# Minecraft versions are resolved against Mojang's version manifest (piston-meta).
# NeoForge versions are resolved against NeoForge's maven metadata, matched to the Minecraft version by prefix (1.21.1 -> 21.1.x, 26.1 -> 26.1.x).
# The NeoForge installer is run with --installServer on first use, and skipped when the args file for the version already exists.
# Dependencies:
#	jq	Optional, only used by dynamic mode
#	curl	Optional, only used by dynamic mode
#	java	Required to run the NeoForge installer
# Required configuration variables:
#	NEOFORGE_MINECRAFT_VERSION	Set to latest for the latest release, latest-snapshot for the latest snapshot, or an exact version id such as 1.21.1.
#	NEOFORGE_VERSION		Set to latest for the newest stable NeoForge for the Minecraft version, or an exact NeoForge version such as 21.1.266.
#	JVM				The command to launch the Java Virtual Machine.
# Exit codes:
#	69	EX_UNAVAILABLE	Set if a request to Mojang or NeoForge fails to resolve/connect, or returns a non-2xx HTTP response.
#	74	EX_IOERR	Set if the installer or the args file is missing after the install step.
#	78	EX_CONFIG	Set if the Java Virtual Machine or a requested version could not be resolved.
#	127	EX_CMDNOTFOUND	Set if jq or curl are not available.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null

# Configure the environment
. ./env.sh

# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'NeoForge Server Launch Script v1.0'

depends jq
depends curl

# Resolve the Minecraft version from Mojang's manifest
log 'Pulling version manifest from Mojang.'
case "$NEOFORGE_MINECRAFT_VERSION" in
latest)
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.release'
	;;
latest-snapshot)
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.snapshot'
	;;
*)
	mc_version="$NEOFORGE_MINECRAFT_VERSION"
	http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_check '[.versions[].id] | index("'"$mc_version"'") != null'
	if [[ "$mc_check" != 'true' ]]; then
		error "Failed to resolve Minecraft version \"$mc_version\"; no matching version was found in Mojang's manifest."
		fatal $EX_CONFIG 'Please check the NEOFORGE_MINECRAFT_VERSION setting in quickstart.env.'
	fi
	;;
esac
log "Minecraft version: $mc_version"

# Build the NeoForge version prefix for this Minecraft version
# 1.21.1 -> 21.1. ; 1.21 -> 21.0. ; 26.1 -> 26.1.
prefix_parts="${mc_version#1.}"
if [[ "$prefix_parts" = "$mc_version" ]]; then
	prefix_parts="$mc_version"
fi
IFS='.' read -r prefix_major prefix_minor prefix_patch <<< "$prefix_parts"
prefix_minor="${prefix_minor:-0}"
neoforge_prefix="$prefix_major.$prefix_minor."

# Fetch NeoForge's maven metadata to a scratch file
metadata_file=$( mktemp )
prepend_trap "rm -f '$metadata_file'" EXIT
http_get_file https://maven.neoforged.net/releases/net/neoforged/neoforge/maven-metadata.xml "$metadata_file"

# Pull the versions for this Minecraft version, skipping alpha, beta and snapshot builds
available_versions=$( grep -o '<version>[^<]*</version>' "$metadata_file" | sed -e 's/<[^>]*>//g' | grep -E "^${neoforge_prefix//./\\.}[0-9]+$" )

if [[ "$NEOFORGE_VERSION" = 'latest' ]]; then
	neoforge_version=$( printf '%s\n' "$available_versions" | tail -n 1 )
else
	neoforge_version="$NEOFORGE_VERSION"
	if ! printf '%s\n' "$available_versions" | grep -qx -- "$neoforge_version"; then
		error "Failed to resolve NeoForge version \"$neoforge_version\" for Minecraft $mc_version; no matching stable version was found in NeoForge's maven metadata."
		fatal $EX_CONFIG 'Please check the NEOFORGE_VERSION setting in quickstart.env.'
	fi
fi

if [[ -z "$neoforge_version" ]]; then
	fatal $EX_CONFIG "No stable NeoForge release was found for Minecraft $mc_version. Please check the NEOFORGE_MINECRAFT_VERSION setting in quickstart.env."
fi
log "NeoForge version: $neoforge_version"

# Run the installer only when the args file for this version is missing
args_file="libraries/net/neoforged/neoforge/$neoforge_version/unix_args.txt"
installer_jar="neoforge-$neoforge_version-installer.jar"
installer_url="https://maven.neoforged.net/releases/net/neoforged/neoforge/$neoforge_version/neoforge-$neoforge_version-installer.jar"

command -v "$JVM" >/dev/null 2>&1 || {
	error 'Failed to launch NeoForge server; "'"$JVM"'" not found!'
	fatal $EX_CONFIG 'Please install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.'
}

if ! [ -f "$args_file" ]; then
	if ! [ -s "$installer_jar" ]; then
		log "Downloading $installer_jar from $installer_url..."
		rm -f "$installer_jar" >/dev/null
		http_get_file "$installer_url" "$installer_jar"
	fi

	if ! [ -s "$installer_jar" ]; then
		error "Failed to download the NeoForge installer \"$installer_jar\"."
		fatal $EX_IOERR 'Failed to download the NeoForge installer from the NeoForge maven repository.'
	fi

	log "Installing NeoForge $neoforge_version server..."
	$JVM -jar "$installer_jar" --installServer || {
		fatal $EX_IOERR 'The NeoForge installer failed. See its output above.'
	}

	if ! [ -f "$args_file" ]; then
		error "Failed to launch NeoForge server; the args file \"$args_file\" was not produced by the installer."
		fatal $EX_IOERR 'Please check the installer output above.'
	fi
fi

line_feed

log 'Launching NeoForge using args from "'"$args_file"'" with the options from user_jvm_args.txt and the args "'"$@"'"...'

trap 'fatal '"$EX_SIGINT"' "User sent SIGINT (Ctrl+C). Exiting."' INT
$JVM -server @user_jvm_args.txt "@$args_file" "$@"
trap - INT
