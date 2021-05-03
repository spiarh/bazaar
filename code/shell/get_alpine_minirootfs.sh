#!/usr/bin/env bash

VERSION="$1"
URL="http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-minirootfs-$VERSION-x86_64.tar.gz"
BASENAME="$(basename "$URL")"

if ! [[ -f "$BASENAME" ]]; then
  echo ">>> Download $URL"
  curl -fsSLO "$URL"
else
  echo ">>> $BASENAME already present"
fi
