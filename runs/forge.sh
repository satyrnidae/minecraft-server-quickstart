#!/bin/bash
# Launches a Minecraft Forge server.
# Set FORGE_ARGS to the args file from your forge install's default script for a static install, or set it to dynamic to resolve and install a Forge build automatically.
# Dynamic mode resolves Minecraft versions against Mojang's version manifest (piston-meta), and Forge builds against Forge's promotions file.
# The Forge installer is run with --installServer on first use, and skipped when the args file for the build already exists.
# Dependencies:
#	jq	Optional, only used by dynamic mode
#	curl	Optional, only used by dynamic mode
#	java	Required by dynamic mode to run the Forge installer
# Required configuration variables:
#	JVM			The command to launch the Java Virtual Machine.
#	FORGE_ARGS		Set to dynamic to resolve and install a Forge build, or set to the args file from your forge install's default script.
#	FORGE_MINECRAFT_VERSION	If FORGE_ARGS is set to dynamic, this will determine which Minecraft version is used. Set to latest for the latest release, latest-snapshot for the latest snapshot, or an exact version id such as 1.21.1.
#	FORGE_BUILD		If FORGE_ARGS is set to dynamic, this will determine which Forge build is used. Set to recommended or latest for the matching promoted build, or an exact Forge version such as 52.1.20.
# Exit codes:
#	69	EX_UNAVAILABLE	Set if a dynamic request to Mojang or Forge fails to resolve/connect, or returns a non-2xx HTTP response.
#	74	EX_IOERR	Set if the Forge installer or the args file is missing after the install step.
#	78	EX_CONFIG	Set if the Java Virtual Machine, the requested version, or the Forge args file could not be located.
#	127	EX_CMDNOTFOUND	Set if dynamic mode is enabled and jq or curl are not available.

# Navigate to the directory of the env script and trap exit for popd
pushd "$(dirname "$0")/.." >/dev/null

# Configure the environment
. ./env.sh

# Add trap for exit
prepend_trap 'popd >/dev/null' EXIT

log 'Custom Forge Launch Script v1.1'

command -v "$JVM" >/dev/null 2>&1 || {
	error 'Failed to launch Minecraft Forge server; "'"$JVM"'" not found!'
	fatal $EX_CONFIG 'Please install a valid JVM for your Minecraft version and set the JVM path in quickstart.env to the java executable.'
}

if [[ "$FORGE_ARGS" = 'dynamic' ]]; then
	depends jq
	depends curl

	# Resolve the Minecraft version from Mojang's manifest
	log 'Pulling version manifest from Mojang.'
	case "$FORGE_MINECRAFT_VERSION" in
	latest)
		http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.release'
		;;
	latest-snapshot)
		http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_version '.latest.snapshot'
		;;
	*)
		mc_version="$FORGE_MINECRAFT_VERSION"
		http_get_json https://piston-meta.mojang.com/mc/game/version_manifest_v2.json mc_check '[.versions[].id] | index("'"$mc_version"'") != null'
		if [[ "$mc_check" != 'true' ]]; then
			error "Failed to resolve Minecraft version \"$mc_version\"; no matching version was found in Mojang's manifest."
			fatal $EX_CONFIG 'Please check the FORGE_MINECRAFT_VERSION setting in quickstart.env.'
		fi
		;;
	esac
	log "Minecraft version: $mc_version"

	# Resolve the Forge build from the promotions file
	log 'Pulling Forge promotions.'
	case "$FORGE_BUILD" in
	recommended|latest)
		http_get_json https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json forge_build ".promos[\"$mc_version-$FORGE_BUILD\"]"
		if [[ -z "$forge_build" || "$forge_build" = 'null' ]]; then
			fatal $EX_CONFIG "Forge does not promote a $FORGE_BUILD build for Minecraft $mc_version. Please choose another FORGE_MINECRAFT_VERSION or set FORGE_BUILD to an exact Forge version."
		fi
		;;
	*)
		forge_build="$FORGE_BUILD"
		;;
	esac
	forge_version="$mc_version-$forge_build"
	log "Forge version: $forge_version"

	# Run the installer only when the args file for this build is missing
	args_file="libraries/net/minecraftforge/forge/$forge_version/unix_args.txt"
	installer_jar="forge-$forge_version-installer.jar"
	installer_url="https://maven.minecraftforge.net/net/minecraftforge/forge/$forge_version/forge-$forge_version-installer.jar"

	if ! [ -f "$args_file" ]; then
		if ! [ -s "$installer_jar" ]; then
			log "Downloading $installer_jar from $installer_url..."
			rm -f "$installer_jar" >/dev/null
			http_get_file "$installer_url" "$installer_jar"
		fi

		if ! [ -s "$installer_jar" ]; then
			error "Failed to download the Forge installer \"$installer_jar\"."
			fatal $EX_IOERR 'Failed to download the Forge installer from the Forge maven repository.'
		fi

		log "Installing Forge $forge_version server..."
		$JVM -jar "$installer_jar" --installServer || {
			fatal $EX_IOERR 'The Forge installer failed. See its output above.'
		}
	fi

	FORGE_ARGS="$args_file"
fi

# Accept the args path with or without a leading @
forge_args_file="${FORGE_ARGS#@}"

if ! [ -f "$forge_args_file" ]; then
	error 'Failed to launch Minecraft Forge server; Forge launch args file "'"$forge_args_file"'" could not be found.'
	fatal $EX_CONFIG 'Please ensure your FORGE_ARGS setting in quickstart.env is correct.'
fi

log 'Launching Forge using args from "'"$forge_args_file"'"...'
$JVM -server @user_jvm_args.txt "@$forge_args_file" "$@"
