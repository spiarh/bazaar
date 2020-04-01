FROM r.spiarh.fr/alpine:latest

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing lldpd

ENTRYPOINT ["lldpd", "-dd", "-r"]
