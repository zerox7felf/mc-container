#!/bin/sh

# Make extra-double-sure that we are in the right dir
cd /opt/minecraft

SERVER_VERSION=${SERVER_VERSION:-latest}

# If we have no installed version, or if the installed version does not match requested version,
# download a new server.jar file.
if [ ! -f server/installed_version -o "$(cat server/installed_version 2> /dev/null)" != "$SERVER_VERSION" ]; then

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

    # If EULA not accepted, start server and accept EULA
    if [ ! -f server/eula.txt ] || grep "eula=false" server/eula.txt &> /dev/null; then
        cd server/
        java -jar server.jar --nogui
        sed -i 's/eula=false/eula=true/' eula.txt
        cd ..
    fi

    # Mark successful version installed
    echo "$SERVER_VERSION" > server/installed_version
fi

# Start server
cd server/
java -jar server.jar $JAVA_OPTS --nogui
