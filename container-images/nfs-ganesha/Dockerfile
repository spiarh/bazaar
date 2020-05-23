FROM opensuse/leap:15.2

RUN zypper ar --no-gpgcheck --no-refresh https://download.opensuse.org/repositories/home:/lcavajani:/branches:/filesystems:/ceph/openSUSE_Leap_15.2/home:lcavajani:branches:filesystems:ceph.repo && \
    zypper ref && \
    zypper in -y home_lcavajani_branches_filesystems_ceph:nfs-ganesha nfs-ganesha-xfs nfs-ganesha-vfs && \
    zypper clean -a

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
