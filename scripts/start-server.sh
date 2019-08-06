#!/usr/bin/env sh

set -eu
set -o pipefail

EULA=${EULA:-false}
JVM_MEM_INIT=${JVM_MEM_INIT:-1024M}
JVM_MEM_MAX=${JVM_MEM_MAX:-1024M}
RCON_PASSWORD=${RCON_PASSWORD:-}

cd $(pwd)/config

if [ $(ls -1 ../overrides | wc -l) != "0" ]; then
    echo "Copying configuration overrides..."
    for file in ../overrides/*; do
        echo "    $(basename ${file})"
        cp ${file} .
    done
    echo "done!"
fi

if [ -n "$RCON_PASSWORD" ]; then
    echo "rcon.password=${RCON_PASSWORD}" >> server.properties
fi

echo "Copying configuration defaults..."
for file in ../defaults/*; do
    if [ ! -f "$(basename ${file})" ]; then
        echo "    $(basename ${file})"
        cp ${file} .
    fi
done
echo "done!"

if ! grep -q eula=true eula.txt; then
    if [ "$EULA" != "true" ]; then
        echo "You must accept the Minecraft EULA to run the server! Read it at:"
        echo "> https://account.mojang.com/documents/minecraft_eula"
        echo "and then restart the server with EULA=true to accept the EULA."
        exit 1
    else
        sed -e "/^eula=/ s/=.*$/=${EULA}/" -i"" eula.txt
    fi
fi

sed -e "/^(query\.|server-)port=/ s/\d+/25565/" \
    -e "/^rcon.port=/ s/\d+/25575/" \
    -i"" server.properties

exec mc-server-runner --shell sh java -Xms${JVM_MEM_INIT} -Xmx${JVM_MEM_MAX} -Dlog4j.configurationFile=log4j2.xml -jar ../bin/minecraft-server.jar --nogui --universe=../server
