# podman run --name mariadb-client spiarh.fr/mariadb-client

FROM r.spiarh.fr/alpine:latest

RUN apk add mariadb-client

ENTRYPOINT ["mysql", "--sigint-ignore"]
