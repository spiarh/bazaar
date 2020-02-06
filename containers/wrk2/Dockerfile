FROM r.spiarh.fr/alpine:latest as builder

WORKDIR /tmp
RUN apk add --update --no-cache alpine-sdk zlib-dev openssl-dev wget git
RUN git clone https://github.com/giltene/wrk2 && \
    cd wrk2 && \
    make && strip wrk && \
    mv wrk wrk2

FROM r.spiarh.fr/alpine:latest

RUN apk add --update --no-cache curl bash \
        so:libcrypto.so.1.1 so:libssl.so.1.1 so:libgcc_s.so.1

COPY --from=builder /tmp/wrk2 /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/wrk2"]
