#!/bin/bash

# Make extra-double-sure that we are in the right dir
cd /opt/minecraft

# Set defaults, verify required parameters are set
if [ -z "$RCON_PASSWD" ]; then echo "Missing RCON_PASSWD!"; exit 1; fi
SERVER_VERSION=${SERVER_VERSION:-latest}

function install_new_version {
    pushd /opt/minecraft

    if [[ "$SERVER_VERSION" =~ ^fabric-.*$ ]]; then
        # Fabric server
        echo "Getting fabric server..."

        fabric_mc_version="$(echo "$SERVER_VERSION" | cut -d- -f2)"
        fabric_loader_version="$(echo "$SERVER_VERSION" | cut -d- -f3)"
        fabric_installer_version="$(echo "$SERVER_VERSION" | cut -d- -f4)"

        if [ -z "$fabric_mc_version" ]; then
            echo "Missing MC version for fabric download!"; exit 1
        elif [ -z "$fabric_loader_version" ]; then
            echo "Missing Fabric Loader version for fabric download!"; exit 1
        elif [ -z "$fabric_installer_version" ]; then
            echo "Missing Fabric Installer version for fabric download!"; exit 1
        fi
        
        echo "Downloading Fabric jar for MC $fabric_mc_version, fabric loader $fabric_loader_version, fabric installer $fabric_installer_version..."
        jar_url="https://meta.fabricmc.net/v2/versions/loader/$fabric_mc_version/$fabric_loader_version/$fabric_installer_version/server/jar"
        curl -f -# "$jar_url" -o /opt/minecraft/server/server.jar
        if [ "$?" != 0 ]; then 
            echo "Failed to download server jar for $server_version!"
            exit 1
        fi
    else
        # Vanilla server
        echo "Getting vanilla server..."

        if [ "$SERVER_VERSION" == "latest" ]; then
            # If SERVER_VERSION is "latest", look up which actual version that is
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
    fi

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
java $JAVA_OPTS -jar server.jar --nogui &
wait $!
