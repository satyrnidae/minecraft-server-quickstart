#!/bin/bash
echo "Papercraft Shell Server Updater and Launcher v2.0.0"

if [[ "$PAPERCRAFT_JAR" = "dynamic" ]]; then

  which curl &>/dev/null || {
    printf '\nFailed to download from Paper API; curl is not present!\nPlease install curl or ensure it is on your PATH, or set PAPERCRAFT_JAR to a specific jar file.\n'
    exit 127
  }

  which jq &>/dev/null || {
    printf '\nFailed to download from Paper API; jq is not present!\nPlease install jq or ensure it is on your PATH, or set PAPERCRAFT_JAR to a specific jar file.\n'
    exit 127
  }

  # Get the latest version and build from 
  if [[ "$PAPERCRAFT_VERSION" = "latest" ]]; then
    echo "Pulling latest minecraft version from papermc.io."
    latest_version=$( curl -s -X GET \
                      -H 'accept: application/json' \
                      https://api.papermc.io/v2/projects/paper \
                      | jq -r '.versions[-1]' )
    echo "Launching Minecraft v$latest_version!"
  else
    echo "Pulling latest $PAPERCRAFT_VERSION build from papermc.io."
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

  echo "PaperMC Latest Version: $filename"

  if [ -f "$filename" ]; then
    echo "Checking SHA256 sum of existing file..."
    exists_sha256=$( sha256sum "$filename" | cut -d " " -f 1 )
    echo "Expected: $sha256"
    echo "Got:      $exists_sha256"
  fi

  while ! [[ "$sha256" = "$exists_sha256" ]]; do
    echo "Checksum mismatch:"
    echo "Expected: $sha256"
    echo "Got:      $exists_sha256"
    echo "Removing any existing file..."
    rm -f $filename
    download_url="https://api.papermc.io/v2/projects/paper/versions/$latest_version/builds/$latest_build/downloads/$filename"
    echo "Downloading from $download_url..."
    curl -X 'GET' \
        $download_url \
        -H 'accept: application/json' \
        --output $filename
    echo "Download complete."
    echo "Verifying checksum..."
    exists_sha256=$( sha256sum $filename | cut -d " " -f 1 )
  done

  echo "Verified PaperMC $latest_version.$latest_build!"
fi

which $JVM &>/dev/null || {
  printf '\nFailed to launch PaperMC; %s was not found!\nPlease ensure your JVM is set correctly in quickstart.env.\n' "${JVM}"
  exit 127
}

printf '\nLaunching the server with the options from user_jvm_args.txt...\n'

$JVM -server @user_jvm_args.txt -jar $filename "$@"
