ARG REGISTRY

FROM ${REGISTRY}/alpine:latest

LABEL maintainer="_me@spiarh.fr"

RUN addgroup -g 2811 -S mysql && adduser -u 2811 -s /bin/false -S -D -G mysql mysql

RUN apk add --no-cache mariadb mariadb-client mariadb-server-utils tzdata

# create dirs
# mysql user needs access to program directories
# Redirect logs to stdout/sterr
RUN mkdir /entrypoint-initdb.d && \
    mkdir -p /run/mysqld && \
    mkdir -p /var/lib/mysql && \
    mkdir -p /var/log/mysql && \
    touch /var/log/mysql/error.log && \
    touch /var/log/mysql/access.log && \
    touch /tmp/mysql.sock && \
    touch /run/mysqld/mysql.sock && \
    chown -R mysql:mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql && \
    chown -R mysql:mysql /var/log/mysql && \
    chown mysql:mysql /tmp/mysql.sock /run/mysqld/mysql.sock && \
    ln -sf /dev/stdout /var/log/mysql/access.log && \
    ln -sf /dev/stderr /var/log/mysql/error.log && \
    rm -f /etc/my.cnf.d/mariadb-server.cnf

VOLUME ["/etc/my.cnf.d", "/var/lib/mysql"]
WORKDIR /var/lib/mysql

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

USER 2811

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
