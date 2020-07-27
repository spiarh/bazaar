FROM golang:1.14-alpine AS builder

ARG VERSION=2.7.1

ENV GOPATH=/go
ENV GO_REGISTRY=src/github.com/docker

RUN set -ex && apk add --no-cache git make

RUN mkdir -p "${GOPATH}/${GO_REGISTRY}" && \
    wget "https://github.com/docker/distribution/archive/v${VERSION}.tar.gz" && \
    tar zxf "v${VERSION}.tar.gz" && \
    mv "distribution-${VERSION}" "${GO_REGISTRY}/distribution" && \
 	cd "${GO_REGISTRY}/distribution" && \
	make bin/registry && \
    mv "${GOPATH}/${GO_REGISTRY}/distribution/bin/registry" /go/bin/registry

FROM r.spiarh.fr/alpine:latest

LABEL maintainer="_me@spiarh.fr"

RUN set -ex && \
    apk add --no-cache ca-certificates apache2-utils

COPY --from=builder /go/bin/registry /usr/local/bin/registry

EXPOSE 5000

USER 1871

ENTRYPOINT ["/usr/local/bin/registry"]

CMD ["serve", "/etc/docker/registry/config.yml"]
