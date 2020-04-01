# https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7
ARG VERSION=7.0.0

FROM r.spiarh.fr/alpine:latest

LABEL maintainer="_me@spiarh.fr"

RUN apk add --no-cache \
		ca-certificates less ncurses-terminfo-base \
	    krb5-libs libgcc libintl libssl1.1 libstdc++ \
	    tzdata  userspace-rcu zlib icu-libs curl && \
    apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust

RUN curl -L "https://github.com/PowerShell/PowerShell/releases/download/v${VERSION}/powershell-${VERSION}-linux-alpine-x64.tar.gz" -o /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    rm -f /tmp/powershell.tar.gz && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh

ENTRYPOINT ["/usr/local/bin/pwsh"]
