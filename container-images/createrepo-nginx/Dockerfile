FROM opensuse/leap

# Install nginx
RUN zypper ref && \
    zypper -n in nginx glibc-locale createrepo && \
    zypper clean -a

# Nginx user needs access to program directories
RUN touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid && \
    chown -R nginx:nginx /var/log/nginx

# Redirect logs to stdout/sterr
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Define mountable directories.
VOLUME ["/etc/nginx/vhosts.d", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/srv/www/htdocs"]

# Define working directory.
WORKDIR /etc/nginx

# Copy local configuration
COPY root/ /

# Expose ports.
EXPOSE 8080

# Define entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Define default command.
CMD ["nginx", "-g", "daemon off;"]
