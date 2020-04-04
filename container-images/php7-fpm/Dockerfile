ARG REGISTRY

FROM ${REGISTRY}/alpine:latest

# minor release
ARG VERSION=7.3

LABEL maintainer="_me@spiarh.fr"

RUN addgroup -g 2111 -S nginx && adduser -u 2111 -s /bin/false -S -D -G nginx nginx

RUN apk add --no-cache \
    less \
    "php7~=${VERSION}" \
    php7-apcu \
    php7-bcmath \
    php7-bz2 \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-exif \
    php7-fpm \
    php7-gd \
    php7-gettext \
    php7-gmp \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-mcrypt \
    php7-memcached \
    php7-mysqli \
    php7-odbc \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-pdo_dblib \
    php7-pdo_odbc \
    php7-pdo_mysql \
    php7-pdo_pgsql \
    php7-pdo_sqlite \
    php7-pgsql \
    php7-phar \
    php7-session \
    php7-simplexml \
    php7-soap \
    php7-sqlite3 \
    php7-xml \
    php7-xmlreader \
    php7-xmlrpc \
    php7-xmlwriter \
    php7-zip

RUN mkdir -p /run/php && \
    chown -Rf nginx:nginx /run/php

COPY ./php-fpm.conf /etc/php7/php-fpm.conf
COPY ./php.ini /etc/php7/php.ini
COPY ./www.conf /etc/php7/php-fpm.d/www.conf

# default conf to unix socket
EXPOSE 9000

USER 2111

ENTRYPOINT ["php-fpm7", "--nodaemonize", "--force-stderr"]
