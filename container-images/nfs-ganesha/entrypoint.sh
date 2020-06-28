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

if [ "${1#-}" != "$1" ]; then
    echo ">>> Starting Ganesha-NFS"
    init_dbus
    set -- ganesha.nfsd "$@"
fi

if [ "$1" = "ganesha.nfsd" ]; then
    echo ">>> Starting Ganesha-NFS"
    init_dbus
    shift
    set -- ganesha.nfsd "$@"
fi

exec "$@"
