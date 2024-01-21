FROM alpine:latest

RUN apk update && apk add curl jq openjdk17-jre-headless

WORKDIR /opt/minecraft

COPY ./get_jar.sh /opt/minecraft/get_jar.sh
COPY ./run.sh /opt/minecraft/run.sh

CMD ["/opt/minecraft/run.sh"]

