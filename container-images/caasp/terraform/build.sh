#!/usr/bin/env bash

REPO_ENV="$1"
REPO="$2"
VERSION=

retrieve_version() {
  local output=$(sudo podman run --rm -ti registry.suse.com/suse/sle15 sh -c "zypper rr -a && zypper ar -G $REPO $REPO_ENV > /dev/null 2>&1 && zypper --no-color --no-gpg-checks info -r $REPO_ENV terraform")

  if [[ $? -eq 0 ]]; then
    # 0.1.11 ^M$
    VERSION="$(echo -n "$output" | grep --color=never "Version" | sed 's/V.*: //' | tr -d ' \t\n\r')"

    echo ">>> INFO: terraform version found, $VERSION"
    return
  fi

  if [[ -z $VERSION ]]; then
    echo ">>> ERROR: no terraform version found" && exit 1
  fi
}

build_container() {
  local IMAGE_NAME="terraform:$REPO_ENV-$VERSION"

  echo ">>> INFO: Build $IMAGE_NAME"
  sudo podman build --no-cache -t "$IMAGE_NAME" \
       --build-arg VERSION="$VERSION" \
       --build-arg REPO_ENV="$REPO_ENV" \
       --build-arg REPO="$REPO" .
}

retrieve_version
build_container
