ARG REGISTRY

FROM ${REGISTRY}/alpine:latest

# Network, DNS
RUN echo "http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add --no-cache \
      bash bind-tools bird bind-tools bridge-utils \
      conntrack-tools curl \
      dhcping \
      ebtables ethtool \
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
    openssl openssh \
    file jq util-linux vim

CMD ["bash", "-l"]
