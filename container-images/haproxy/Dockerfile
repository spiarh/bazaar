FROM docker.io/spiarh/alpine:latest

RUN addgroup -g 2211 -S haproxy && adduser -u 2211 -s /bin/false -S -D -G haproxy haproxy

# allow bind on ports below 1024
RUN apk add --no-cache haproxy libcap && \
    setcap CAP_NET_BIND_SERVICE=+ep /usr/sbin/haproxy

RUN mkdir -p /run/haproxy && \
    touch /run/haproxy/haproxy.pid && \
    chown -Rf haproxy:haproxy /run/haproxy /var/lib/haproxy

ADD ./haproxy.cfg /etc/haproxy/haproxy.cfg

# https://www.haproxy.org/download/1.8/doc/management.txt
# "4. Stopping and restarting HAProxy"
# "when the SIGTERM signal is sent to the haproxy process, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent to the haproxy process"
STOPSIGNAL SIGUSR1

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

USER 2211

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["haproxy", "-f", "/etc/haproxy/haproxy.cfg"]
