FROM jenkins-slave/default:stable

# Install openstack requirements
RUN zypper ref && \
    zypper -n in python3-openstackclient && \
    zypper clean -a
