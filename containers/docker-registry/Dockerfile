FROM golang:1.12-alpine AS builder

RUN set -ex && apk add --no-cache git

RUN go get github.com/docker/distribution/cmd/registry

FROM r.spiarh.fr/alpine:latest

RUN set -ex && \
    apk add --no-cache ca-certificates apache2-utils

COPY --from=builder /go/bin/registry /bin/registry

VOLUME ["/var/lib/registry"]
EXPOSE 5000

ENTRYPOINT ["registry"]
CMD ["serve", "/etc/docker/registry/config.yml"]
