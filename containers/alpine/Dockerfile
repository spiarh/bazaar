ARG VERSION=3.11.4

FROM scratch

ADD alpine-minirootfs-${VERSION}-x86_64.tar.gz /

RUN apk --no-cache update && \
    apk --no-cache upgrade

CMD ["/bin/sh"]
