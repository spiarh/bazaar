# podman run --net=host --uts=host --privileged --name lldpd spiarh.fr/lldpd

FROM r.spiarh.fr/alpine:latest

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing lldpd

ENTRYPOINT ["lldpd", "-dd", "-r"]
