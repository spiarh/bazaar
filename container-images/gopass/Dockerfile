FROM golang:1.14-alpine AS builder

ARG VERSION=1.9.2

RUN apk add --no-cache git make curl gcc libc-dev ncurses

RUN curl -OL "https://github.com/gopasspw/gopass/archive/v${VERSION}.tar.gz" && \
    tar zxf "v${VERSION}.tar.gz" && cd "gopass-${VERSION}" && \
    make full && mv ./gopass-linux-amd64-full /go/bin/gopass-full

FROM r.spiarh.fr/alpine:latest

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /go/bin/gopass-full /usr/local/bin/gopass-full

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN apk add --no-cache gnupg

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
