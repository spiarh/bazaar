FROM docker.io/spiarh/alpine:latest

# Network, DNS
RUN set -ex && \
    echo "http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add --no-cache \
    bash bind-tools bird bind-tools bridge-utils \
    conntrack-tools curl \
    dhcping \
    ethtool \
    fping \
    iftop iperf3 iproute2 iptables \
    iptraf-ng iputils ipvsadm \
    libc6-compat liboping \
    mtr \
    net-snmp-tools netcat-openbsd nftables \
    ngrep nmap nmap-nping \
    scapy socat strace \
    tcpdump tcptraceroute

# Misc
RUN apk add --no-cache \
    busybox-extras mariadb-client \
    openssl openssh etcd-ctl \
    file jq util-linux vim

ENTRYPOINT ["bash", "-l"]
