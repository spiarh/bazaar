FROM golang:alpine AS builder

ARG CGO_ENABLED=0

RUN apk update && apk add --no-cache git make

WORKDIR $GOPATH/src/github.com/SUSE/skuba
COPY . .

RUN make

FROM scratch

COPY --from=builder /go/bin/skuba /go/bin/skuba

ENTRYPOINT ["/go/bin/skuba"]
