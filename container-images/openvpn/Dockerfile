FROM r.spiarh.fr/alpine:latest

RUN apk update && apk add openvpn iptables

ADD entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 2294

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
