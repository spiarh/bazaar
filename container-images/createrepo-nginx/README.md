# createrepo-nginx

Create a container that creates a RPM repository with createrepo from a
directory mounted in the container to "/srv/www/htdocs/" and exposes it
with nginx on port 8080.

There is no specific configuration for createrepo and nginx, it uses
the default one.

**Packages**

1. Create the directory for the packages

```console
mkdir -p /root/repo/packages
```

2. Copy packages in that repo

3. Change owner of the directory

```console
chown -Rf 9999.9999 /root/repo
```

**Image**

1. Build

```console
podman build -t createrepo-nginx:1.0 .
```

2. Run

```console
podman run -p 8080:8080 -d --restart always --name maintenance-updates-repo \
    --mount type=bind,source="/root/repo/packages",target="/srv/www/htdocs/"  \
    createrepo-nginx:1.0
```

**Repo**

SUSE_Maintenance_9425.repo

```
[custom-rpm-repo]
name=Custom RPM Repo
type=rpm-md
baseurl=http://NODE_IP_ADDRESS:8080
gpgcheck=0
enabled=1
```

CLI

```console
zypper ar --refresh --no-gpgcheck http://NODE_IP_ADDRESS:8080 custom-rpm-repo
```
