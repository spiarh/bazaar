ARG VERSION=1.9.2

FROM golang:1.14-alpine AS builder

RUN apk add --no-cache git make curl gcc libc-dev

RUN curl -OL "https://github.com/gopasspw/gopass/archive/v${VERSION}.tar.gz" && \
    tar zxf "v${VERSION}.tar.gz" && cd "gopass-${VERSION}" && \
    make && mv ./gopass /go/bin

FROM r.spiarh.fr/alpine:latest

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /go/bin/gopass /usr/local/bin/gopass

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN apk add --no-cache gnupg

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
