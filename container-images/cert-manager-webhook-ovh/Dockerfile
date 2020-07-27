FROM golang:1.14-alpine AS builder

ARG BRANCH=master
ENV GO111MODULE=on

RUN apk add --no-cache git

RUN git clone https://github.com/lcavajani/cert-manager-webhook-ovh.git && \
	cd cert-manager-webhook-ovh && \
	git checkout ${BRANCH} && \
	go mod download && \
	CGO_ENABLED=0 go build -o /go/bin/webhook -ldflags '-w -extldflags "-static"' .

ARG REGISTRY

FROM docker.io/spiarh/alpine:latest

ARG REGISTRY

RUN apk add --no-cache ca-certificates

COPY --from=builder /go/bin/webhook /usr/local/bin/webhook

ENTRYPOINT ["/usr/local/bin/webhook"]
