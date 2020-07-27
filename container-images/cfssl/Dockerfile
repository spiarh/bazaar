FROM docker.io/spiarh/alpine:latest

LABEL maintainer="_me@spiarh.fr"

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing cfssl

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /app

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
