#!/usr/bin/env bash

init_dbus() {
    echo ">>> Starting dbus"
    if [ ! -x /var/run/dbus ] ; then
        install -m755 -g 81 -o 81 -d /var/run/dbus
    fi
    rm -f /var/run/dbus/*
    rm -f /var/run/messagebus.pid
    dbus-uuidgen --ensure
    dbus-daemon --system --fork
    sleep 1
}

init_dbus

echo ">>> Starting Ganesha-NFS"
exec /usr/bin/ganesha.nfsd -F -L /dev/stdout -f /etc/ganesha/ganesha.conf
