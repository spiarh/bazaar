# caaspctl-product

```
export SKUBA_VERSION="0.7.1-3.4.1"
export SKUBA_REPO="http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40:/Update/standard/"
export SKUBA_REPO_ENV="update"
sudo podman build --no-cache -t "skuba-$SKUBA_REPO_ENV-$SKUBA_VERSION"
     --build-arg VERSION="$SKUBA_VERSION" \
     --build-arg REPO_ENV="$SKUBA_REPO_ENV" \
     --build-arg REPO="$SKUBA_REPO" .
```

```
sudo podman run -ti --rm \
    -v "$PWD":/app \
    -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) \
    -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
    -u $(id -u):$(id -g) \
    skuba:update-0.7.1-3.4.1  node bootstrap --user sles --sudo --target 10.86.5.68.omg.howdoi.website master0
```
