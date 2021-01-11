ARG FROM_IMAGE_BUILDER
ARG FROM_IMAGE

FROM ${FROM_IMAGE_BUILDER} AS builder

ARG VERSION

RUN apk add --no-cache git make curl

RUN curl -OL "https://github.com/google/go-containerregistry/archive/v${VERSION}.tar.gz" && \
    tar zxf "v${VERSION}.tar.gz" && cd "go-containerregistry-${VERSION}" && \
    go install ./cmd/crane && \
    go install ./cmd/gcrane && \
    go install ./cmd/registry

FROM ${FROM_IMAGE}

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /go/bin/crane /usr/local/bin/crane
COPY --from=builder /go/bin/gcrane /usr/local/bin/gcrane
COPY --from=builder /go/bin/registry /usr/local/bin/registry

ENTRYPOINT ["sh", "-c"]
