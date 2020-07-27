run as root in a rootless container

podman run -ti --rm \
    -v "/home/$USER/.gnupg:/root/.gnupg" \
    -v "/run/user/$UID/gnupg:/run/user/$UID/gnupg:ro" \
    -v "/home/$UID/.gopass:/root" \
     r.spiarh.fr/gopass
