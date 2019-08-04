#!/usr/bin/env sh

set -eu
set -o pipefail

EULA=${EULA:-false}
JVM_MEM_INIT=${JVM_MEM_INIT:-1024M}
JVM_MEM_MAX=${JVM_MEM_MAX:-1024M}

cd $(pwd)/config

for file in ../defaults/*; do
    [ -f "$(basename ${file})" ] || cp ${file} .
done

if [ -n "$EULA" ]; then
    sed -e "s/^eula=.*$/eula=${EULA}/" -i"" eula.txt
fi

grep -q eula=true eula.txt || (
    echo "You must accept the Minecraft EULA to run the server! Read it at:"
    echo "> https://account.mojang.com/documents/minecraft_eula"
    echo "and then restart the server with EULA=true to accept the EULA."
    exit 1
)

sed -e "/^(query\.|server-)port=/g s/\d+/25565/" \
    -e "/^rcon.port=/g s/\d+/25575/" \
    -i"" server.properties

exec mc-server-runner --shell sh java -Xms${JVM_MEM_INIT} -Xmx${JVM_MEM_MAX} -Dlog4j.configurationFile=log4j2.xml -jar ../bin/minecraft-server.jar --nogui --universe=../server
