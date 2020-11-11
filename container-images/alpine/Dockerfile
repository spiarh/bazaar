FROM scratch

ARG VERSION=3.12.1

LABEL maintainer="_me@spiarh.fr"

ADD alpine-minirootfs-${VERSION}-x86_64.tar.gz /

RUN addgroup -g 1871 -S regular && adduser -u 1871 -s /bin/false -S -D -G regular regular

RUN mkdir -p /usr/local/etc

RUN apk --no-cache update && \
    apk --no-cache upgrade

ENTRYPOINT ["/bin/sh"]
