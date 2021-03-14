ARG REGISTRY

FROM ${REGISTRY}/php7-fpm:latest

LABEL maintainer="_me@spiarh.fr"

ARG VERSION=19.0.1
ARG DIST=nextcloud-${VERSION}.tar.bz2
ARG URL=https://download.nextcloud.com/server/releases/$DIST
ARG SHA512=aa4db108bff2b452123e5513bde03fe4c2f1da58c1987d74a246a69714fedf121ca9ed6151609d87c91dd6109419b764ba02c5c3c1669c5ddd5a49118e68f0c0

USER root
RUN apk add --no-cache \
    curl \
    icu-libs \
    php7-fileinfo \
    php7-intl \
    php7-pcntl \
    php7-pecl-imagick \
    php7-pecl-redis \
    php7-posix \
    rsync

# entrypoint.sh and cron.sh dependencies
RUN rm -f /var/spool/cron/crontabs/root && \
    echo '*/5 * * * * php -f /var/www/html/cron.php' > /var/spool/cron/crontabs/www-data

RUN mkdir -p /usr/src/nextcloud && \
    wget -O $DIST $URL && \
    echo "expected SHA512=$(sha512sum $DIST)" && \
    echo "$SHA512  $DIST" | sha512sum -c - && \
    tar -xf $DIST -C /usr/src/nextcloud --strip-components=1 && \
    rm -f $DIST && \
    mkdir -p /usr/src/nextcloud/data /usr/src/nextcloud/custom_apps && \
    mkdir -p /var/www/html/data && \
    chown -Rf nginx:nginx /usr/src/nextcloud /var/www && \
    chmod +x /usr/src/nextcloud/occ

VOLUME /var/www/html

WORKDIR /usr/src/nextcloud
USER 2111

COPY *.sh /usr/local/bin/
COPY upgrade.exclude /
COPY config/* /usr/src/nextcloud/config/
COPY php.ini /etc/php7/php.ini

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm7", "--nodaemonize", "--force-stderr"]
