FROM docker.io/spiarh/alpine:latest

RUN addgroup -g 2711 -S etcd && adduser -u 2711 -s /bin/false -S -D -G etcd etcd

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing etcd etcd-ctl

RUN mkdir -p /run/etcd /var/lib/etcd && \
    chown -Rf etcd:etcd /run/etcd /var/lib/etcd

# Alpine Linux doesn't use pam, which means that there is no /etc/nsswitch.conf,
# but Golang relies on /etc/nsswitch.conf to check the order of DNS resolving
# (see https://github.com/golang/go/commit/9dee7771f561cf6aee081c0af6658cc81fac3918)
# To fix this we just create /etc/nsswitch.conf and add the following line:
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

EXPOSE 2379 2380 2381

COPY entrypoint.sh prestop-hook.sh /usr/local/bin/

USER 2711

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
