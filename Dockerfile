FROM alpine AS get-base

RUN apk add --update --no-cache curl

FROM get-base AS get-runner

ARG ARCH=amd64
ARG RUNNER_VERSION=1.3.2

RUN curl -fsSL https://github.com/itzg/mc-server-runner/releases/download/${RUNNER_VERSION}/mc-server-runner_${RUNNER_VERSION}_linux_${ARCH}.tar.gz | tar xz

FROM get-base AS get-server

RUN apk add --update --no-cache jq

ARG VERSION=1.14.4
COPY scripts/get-server.sh ./
RUN ./get-server.sh

FROM openjdk:8-jre-alpine AS server

WORKDIR /opt/minecraft
RUN addgroup -g 1000 minecraft \
    && adduser -Ss /bin/false -u 1000 -G minecraft -h $(pwd) minecraft \
    && mkdir -p bin config defaults server \
    && chown -R minecraft:minecraft $(pwd)
USER minecraft

EXPOSE 25565 25575
VOLUME [ "/opt/minecraft/config", "/opt/minecraft/server" ]

COPY config/ ./defaults/
COPY scripts/start-server.sh ./bin/
COPY --from=get-runner /mc-server-runner /usr/bin/
COPY --from=get-server /minecraft-server.jar ./bin/

CMD [ "bin/start-server.sh" ]
