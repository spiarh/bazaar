ARG FROM_IMAGE_BUILDER
ARG FROM_IMAGE

FROM ${FROM_IMAGE_BUILDER} AS builder

ARG VERSION

RUN apk add --no-cache git make curl gcc libc-dev ncurses bash

RUN curl -OL "https://github.com/genuinetools/reg/archive/v${VERSION}.tar.gz" && \
    tar zxf "v${VERSION}.tar.gz" && cd "reg-${VERSION}" && \
    make && mv ./reg /go/bin/reg

FROM ${FROM_IMAGE}

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /go/bin/reg /usr/local/bin/reg

ENTRYPOINT ["/usr/local/bin/reg"]
