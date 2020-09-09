#
# podman run -v /tmp/.X11-unix:/tmp/.X11-unix \
#	-v /dev/snd:/dev/snd \
#	-v /dev/shm:/dev/shm \
#	-v /etc/machine-id:/etc/machine-id:ro \
#	-e DISPLAY=$DISPLAY \
#	r.spiarh.fr/tor-browser
#
FROM r.spiarh.fr/alpine:latest AS builder
LABEL maintainer="_me@spiarh.fr"

RUN apk add --no-cache curl gnupg

# https://www.torproject.org/projects/torbrowser.html.en
ENV TOR_VERSION 9.5.4

# download tor and check signature
RUN cd /tmp \
	&& curl -sSOL "https://dist.torproject.org/torbrowser/${TOR_VERSION}/tor-browser-linux64-${TOR_VERSION}_en-US.tar.xz" \
	&& curl -sSOL "https://www.torproject.org/dist/torbrowser/${TOR_VERSION}/tor-browser-linux64-${TOR_VERSION}_en-US.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
    && gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org \
    && gpg --output ./tor.keyring --export 0xEF6E286DDA85EA2A4BA7DE684E2C6E8793298290 \
    && gpg --verify tor-browser-linux64-${TOR_VERSION}_en-US.tar.xz.asc tor-browser-linux64-${TOR_VERSION}_en-US.tar.xz \
	&& tar -vxJ --strip-components 1 -C /usr/local/bin -f tor-browser-linux64-${TOR_VERSION}_en-US.tar.xz \
	&& rm -rf tor-browser* "$GNUPGHOME"

FROM r.spiarh.fr/alpine:latest

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /usr/local/bin /usr/local/bin

RUN apk add --no-cache \
    bash \
    ca-certificates \
    dbus-x11 \
    file \
    zenity \
    kdialog \
    xmessage \
    ttf-freefont \
    glib-dev \
    gtk+3.0-dev \
    libxt \
    libc6-compat \
    gcompat && \
    chown -Rf regular:regular /usr/local/bin

ENV HOME /home/regular
ENV LANG C.UTF-8

WORKDIR $HOME
USER regular

ENTRYPOINT ["/bin/bash"]
CMD ["/usr/local/bin/Browser/start-tor-browser", "--log", "/dev/stdout", "--verbose"]
