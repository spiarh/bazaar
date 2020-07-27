#!/usr/bin/env sh

if [ "$1" = "sh" ]; then
  set -- /bin/sh
else
  set -- /usr/local/bin/gopass "$@"
fi

# Avoid warnings about server version
# gpg: WARNING: server 'gpg-agent' is older than us (2.2.5 < 2.2.20)
2>/dev/null exec "$@"
