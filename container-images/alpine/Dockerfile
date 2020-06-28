ARG VERSION=3.12.0

FROM scratch

LABEL maintainer="_me@spiarh.fr"

ADD alpine-minirootfs-${VERSION}-x86_64.tar.gz /

RUN addgroup -g 1871 -S regular && adduser -u 1871 -s /bin/false -S -D -G regular regular

RUN apk --no-cache update && \
    apk --no-cache upgrade

ENTRYPOINT ["/bin/sh"]
