#!/usr/bin/env sh

set -eu
set -o pipefail

EULA=${EULA:-false}
HEAP_SIZE=${HEAP_SIZE:-1024}
JVM_OPTS=${JVM_OPTS:-}
RCON_PASSWORD=${RCON_PASSWORD:-}
SERVER_OPTS=${SERVER_OPTS:-}

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

NURSERY_MINIMUM=$((${HEAP_SIZE} / 2))
NURSERY_MAXIMUM=$((${HEAP_SIZE} * 4 / 5))

JVM_OPTS="${JVM_OPTS} -Xms${HEAP_SIZE}M -Xmx${HEAP_SIZE}M -Xmns${NURSERY_MINIMUM}M -Xmnx${NURSERY_MAXIMUM}M"
JVM_OPTS="${JVM_OPTS} -Xgc:concurrentScavenge -Xgc:dnssExpectedTimeRatioMaximum=3 -Xgc:scvNoAdaptiveTenure"
JVM_OPTS="${JVM_OPTS} -Xdisableexplicitjc -Xtune:virtualized -Dlog4j.configurationFile=log4j2.xml"
SERVER_OPTS="--nogui --universe ../server ${SERVER_OPTS}"

CMD="mc-server-runner java ${JVM_OPTS} -jar ../bin/minecraft-server.jar ${SERVER_OPTS}"
echo "${CMD}"

exec ${CMD}
