FROM r.spiarh.fr/alpine:latest

RUN apk add salt-ssh openssh

VOLUME ["/app"]

WORKDIR /app

ENTRYPOINT ["salt-ssh"]
