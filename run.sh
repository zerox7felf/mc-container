#!/bin/bash

# Make extra-double-sure that we are in the right dir
cd /opt/minecraft

# Set defaults, verify required parameters are set
if [ -z "$RCON_PASSWD" ]; then echo "Missing RCON_PASSWD!"; exit 1; fi
SERVER_VERSION=${SERVER_VERSION:-latest}

function install_new_version {
    pushd /opt/minecraft

    # If SERVER_VERSION is "latest", look up which actual version that is
    if [ "$SERVER_VERSION" == "latest" ]; then
        server_version="$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r ".latest.release")"
        if [ -z "$server_version" ]; then
            echo "Failed to look up latest version"
            exit 1
        fi
    else
        server_version="$SERVER_VERSION"
    fi

    # Download server jar, exit if we fail
    ./get_jar.sh "$server_version" || exit 1

    # Mark successful version installed
    echo "$SERVER_VERSION" > server/installed_version

    popd
}

if [ ! -f server/installed_version ]; then
    # If we have no installed version, run first-time setup
    echo "Performing first-time setup..."
    install_new_version

    pushd /opt/minecraft/server/

    # Start server and accept EULA 
    echo "Starting server and accepting EULA..."
    java -jar server.jar --nogui
    sed -i 's/eula=false/eula=true/' eula.txt
    
    popd
elif [ "$(cat server/installed_version 2> /dev/null)" != "$SERVER_VERSION" ]; then
    # If the installed version does not match requested version, download a new server.jar file
    echo "Installing new version '$SERVER_VERSION'..."
    install_new_version
fi

# Ensure RCON is enabled
echo "Ensuring rcon is enabled..."
sed -i 's/enable-rcon=.*/enable-rcon=true/' /opt/minecraft/server/server.properties
sed -i "s/rcon.password=.*/rcon.password=$RCON_PASSWD/" /opt/minecraft/server/server.properties

# Register shutdown trap
function stop_server_trap {
    echo "Received SIGTERM"
    /opt/minecraft/mcrcon -H 127.0.0.1 -p "$RCON_PASSWD" save-all stop
    exit 0
}
trap stop_server_trap SIGTERM

# Start server
cd /opt/minecraft/server/
java -jar server.jar $JAVA_OPTS --nogui &
wait $!
