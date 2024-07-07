FROM alpine:latest

RUN apk update && apk add bash curl jq openjdk21-jre-headless gcc musl-dev make

# Download, build and install mcrcon into /opt/minecraft
WORKDIR /tmp/mcrcon
RUN curl https://github.com/Tiiffi/mcrcon/archive/refs/tags/v0.7.2.tar.gz -#Lo mcrcon.tar.gz
RUN tar -xf mcrcon.tar.gz
WORKDIR /tmp/mcrcon/mcrcon-0.7.2
RUN make
WORKDIR /opt/minecraft
RUN cp /tmp/mcrcon/mcrcon-0.7.2/mcrcon /opt/minecraft/

# Set up /opt/minecraft dir with our scripts
WORKDIR /opt/minecraft
COPY ./get_jar.sh /opt/minecraft/get_jar.sh
COPY ./run.sh /opt/minecraft/run.sh

ENTRYPOINT ["/opt/minecraft/run.sh"]

