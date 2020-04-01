FROM r.spiarh.fr/fio:latest

LABEL maintainer="_me@spiarh.fr"

RUN apk add --no-cache ioping 

VOLUME /tmp
WORKDIR /tmp

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["fio"]
