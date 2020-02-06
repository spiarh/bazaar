FROM registry.suse.com/suse/sle15

ARG VERSION
ARG REPO_ENV
ARG REPO

RUN zypper ar --no-gpgcheck "${REPO}" "${REPO_ENV}" && \
    zypper in --auto-agree-with-licenses --no-confirm "terraform-${VERSION}" && \
    zypper clean -a

VOLUME ["/app"]

WORKDIR /app

ENTRYPOINT ["/usr/bin/terraform"]
