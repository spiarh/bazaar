#!/usr/bin/env bash
createrepo /srv/www/htdocs
chown -Rf nginx.nginx /srv/www/htdocs
exec "$@"
