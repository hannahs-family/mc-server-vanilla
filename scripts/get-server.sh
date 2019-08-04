#!/usr/bin/env sh

set -eu
set -o pipefail

manifest_url=https://launchermeta.mojang.com/mc/game/version_manifest.json

echo "Getting manifest for version ${VERSION}..."
version_manifest_url=$(curl -fsSL ${manifest_url} | jq --arg version "${VERSION}" --raw-output '[.versions[]|select(.id == $version)][0].url')

echo "Getting download URL for version ${VERSION} server..."
server_url=$(curl -fsSL ${version_manifest_url} | jq --raw-output '.downloads.server.url')

echo "Downloading version ${VERSION} server..."
curl -fsSLo minecraft-server.jar ${server_url}

echo "Done!"
