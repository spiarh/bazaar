FROM scratch

ADD alpine-minirootfs-3.10.2-x86_64.tar.gz /

RUN apk --no-cache update && \
    apk --no-cache upgrade

CMD ["/bin/sh"]
