FROM golang:1.12-alpine AS builder

RUN set -ex && apk add --no-cache git make py2-pip && \
    pip install GitPython

RUN git clone https://github.com/cesanta/docker_auth.git && \
    cd docker_auth/auth_server && \
    make deps && make generate && make


#    #export GOPATH=//go
#    #export PATH=$PATH:$GOPATH/bin
#    # download dependencies
#    make deps
#    # build source
#    make generate
#    make

FROM r.spiarh.fr/alpine:latest

EXPOSE 5001

COPY --from=builder /go/docker_auth/auth_server/auth_server /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/auth_server"]

CMD ["/config/auth_config.yml"]
