FROM r.spiarh.fr/alpine:latest

RUN apk add mariadb-client

WORKDIR /app

ENTRYPOINT ["mysql", "--sigint-ignore"]
