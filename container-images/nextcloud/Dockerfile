ARG REGISTRY

FROM ${REGISTRY}/php7-fpm:latest

LABEL maintainer="_me@spiarh.fr"

ARG VERSION=18.0.3
ARG DIST=nextcloud-${VERSION}.tar.bz2
ARG URL=https://download.nextcloud.com/server/releases/$DIST
ARG SHA512=b1f433dee2e7eea800de8cd8131332530050b6194460a397081a134f63b236f65e33758c60cd8e97a43570d0b6a1baac9e0503535d85a9a34cd63abd50041292

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
    chown -R nginx:nginx /usr/src/nextcloud /var/www && \
    chmod +x /usr/src/nextcloud/occ

VOLUME /var/ww/html

WORKDIR /usr/src/nextcloud
USER 2111

COPY *.sh /usr/local/bin/
COPY upgrade.exclude /
COPY config/* /usr/src/nextcloud/config/
COPY php.ini /etc/php7/php.ini

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm7", "--nodaemonize", "--force-stderr"]
