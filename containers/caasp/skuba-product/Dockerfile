FROM registry.suse.com/suse/sle15

ARG VERSION
ARG REPO_ENV
ARG REPO

RUN zypper ar --no-gpgcheck "${REPO}" "skuba-${REPO_ENV}" && \
    zypper ar --no-gpgcheck http://ibs-mirror.prv.suse.net/ibs/SUSE/Products/SLE-Module-Basesystem/15-SP1/x86_64/product basesystem_pool && \
    zypper in --auto-agree-with-licenses --no-confirm "skuba-${VERSION}" kubernetes-client && \
    zypper clean -a

VOLUME ["/app"]

WORKDIR /app

ENTRYPOINT ["/usr/bin/skuba"]
