#!/bin/sh

mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

/sbin/iptables -t nat -C POSTROUTING -s "$OVPN_SUBNET" -o "$OVPN_NATDEVICE" -j MASQUERADE || {
  /sbin/iptables -t nat -A POSTROUTING -s "$OVPN_SUBNET" -o "$OVPN_NATDEVICE" -j MASQUERADE
}

echo "Running '/usr/sbin/openvpn --cd /etc/openvpn/ --config server.conf'"
exec /usr/sbin/openvpn --cd /etc/openvpn/ --config server.conf
