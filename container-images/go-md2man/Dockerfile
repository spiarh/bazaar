ARG VERSION=1.0.10

FROM golang:1.14-alpine AS builder

RUN apk add --no-cache curl make git

RUN curl -OL "https://github.com/cpuguy83/go-md2man/archive/v${VERSION}.tar.gz" && \
    mkdir -p xdir && \
    tar zxf "v${VERSION}.tar.gz" -C xdir --strip-components 1 && \
    cd xdir && \
    make && \
    mv ./bin/go-md2man /go/bin

FROM r.spiarh.fr/alpine:latest

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /go/bin/go-md2man /usr/local/bin/md2man

WORKDIR /app

ENTRYPOINT ["/usr/local/bin/md2man"]
