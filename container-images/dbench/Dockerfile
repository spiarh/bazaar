FROM r.spiarh.fr/fio:latest

LABEL maintainer="_me@spiarh.fr"

RUN apk add --no-cache ioping 

VOLUME /tmp
WORKDIR /tmp

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["fio"]
