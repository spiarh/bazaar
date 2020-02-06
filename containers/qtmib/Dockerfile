# podman run -ti -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY r.spiarh.fr/qtmib

FROM opensuse/leap:15.1

ENV QT_X11_NO_MITSHM=1

COPY qtmib-1.1-1.x86_64.rpm /qtmib-1.1-1.x86_64.rpm

RUN zypper ref && \
    zypper in -y net-snmp libqt4 libqt4-x11 xorg-x11-fonts-core which && \
    rpm -i /qtmib-1.1-1.x86_64.rpm && \
    rm -vf /qtmib-1.1-1.x86_64.rpm && \
    zypper clean

CMD ["qtmib"]
