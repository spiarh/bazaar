ARG REGISTRY

FROM ${REGISTRY}/alpine:latest

ARG VERSION=1.16.1

LABEL maintainer="_me@spiarh.fr"

RUN addgroup -g 2111 -S nginx && adduser -u 2111 -s /bin/false -S -D -G nginx nginx

RUN apk add --no-cache nginx tzdata

# Nginx user needs access to program directories
# Redirect logs to stdout/sterr
RUN mkdir -p /run/nginx && \
    mkdir -p /srv/www && \
    touch /run/nginx/nginx.pid && \
    chown -Rf nginx:nginx /var/log/nginx /run/nginx /srv/www && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    rm -f /etc/nginx/conf.d/default.conf

COPY ./nginx.conf /etc/nginx/nginx.conf

# Allow a non privileged to update file (e.g postStart)
#RUN chown -f nginx:nginx /etc/nginx/nginx.conf
#    chown -f nginx:nginx /etc/nginx/nginx.conf

EXPOSE 8080 8443

STOPSIGNAL SIGTERM

USER 2111

ENTRYPOINT ["nginx", "-g", "pid /run/nginx/nginx.pid; daemon off;"]
