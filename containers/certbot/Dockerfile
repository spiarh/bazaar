FROM r.spiarh.fr/python3

RUN apk add --no-cache certbot

RUN pip3 install --no-cache --upgrade certbot-dns-ovh

ENTRYPOINT ["certbot"]
