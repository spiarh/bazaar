#!/bin/bash

rules="POSTROUTING -s 192.168.100.0/24 ! -d 192.168.100.0/24 -p tcp -j MASQUERADE
POSTROUTING -s 192.168.100.0/24 ! -d 192.168.100.0/24 -p udp -j MASQUERADE
POSTROUTING -s 192.168.100.0/24 ! -d 192.168.200.0/24 -p tcp -j MASQUERADE
POSTROUTING -s 192.168.100.0/24 ! -d 192.168.200.0/24 -p udp -j MASQUERADE
POSTROUTING -s 192.168.100.0/24 ! -d 192.168.100.0/24 -j MASQUERADE
POSTROUTING -s 192.168.100.0/24 ! -d 192.168.200.0/24 -j MASQUERADE
POSTROUTING -s 192.168.200.0/24 ! -d 192.168.100.0/24 -p tcp -j MASQUERADE
POSTROUTING -s 192.168.200.0/24 ! -d 192.168.100.0/24 -p udp -j MASQUERADE
POSTROUTING -s 192.168.200.0/24 ! -d 192.168.200.0/24 -p tcp -j MASQUERADE
POSTROUTING -s 192.168.200.0/24 ! -d 192.168.200.0/24 -p udp -j MASQUERADE
POSTROUTING -s 192.168.200.0/24 ! -d 192.168.100.0/24 -j MASQUERADE
POSTROUTING -s 192.168.200.0/24 ! -d 192.168.200.0/24 -j MASQUERADE"

if [ "$1" == "delete" ]; then
    while IFS= read -r rule; do
        iptables -v -t nat -D $rule || true
    done <<< "$rules"
fi

if [ "$1" == "add" ]; then
    while IFS= read -r rule; do
        iptables -v -t nat -A $rule
    done <<< "$rules"
fi
