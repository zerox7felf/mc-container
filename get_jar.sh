#!/bin/bash

server_version=$1

echo "Downloading version manifest..."
version_url=$(curl -f -# https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r ".versions.[] | select(.id == \"$server_version\").url")
if [ "$?" != 0 ]; then
    echo "Failed to download version_manifest!"
    exit 1
fi
if [ -z "$version_url" ]; then
    echo "Failed to find version manifest url for $server_version!"
    exit 1
fi

echo "Downloading manifest for $server_version..."
jar_url=$(curl -f -# "$version_url" | jq -r ".downloads.server.url")
if [ "$?" != 0 ]; then 
    echo "Failed to download manifest for $server_version!"
    exit 1
fi

echo "Downloading server.jar from $jar_url..."
curl -f -# "$jar_url" -o /opt/minecraft/server/server.jar
if [ "$?" != 0 ]; then 
    echo "Failed to download server jar for $server_version!"
    exit 1
fi
echo "Done"
