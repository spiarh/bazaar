#!/bin/sh

set -o errexit
set -o nounset

# Constants
HOSTNAME="$(hostname -s)"
AUTH_SKIP_TLS="${AUTH_SKIP_TLS:-false}"
ETCDCTL_FLAGS=""
if [ "${AUTH_SKIP_TLS}" = "true" ]; then ETCDCTL_FLAGS="$ETCDCTL_FLAGS --insecure-skip-tls-verify"; fi
if [ -n "${ETCD_ROOT_PASSWORD:-}" ]; then ETCDCTL_FLAGS="$ETCDCTL_FLAGS --user root:$ETCD_ROOT_PASSWORD"; fi
ETCDCTL="etcdctl $ETCDCTL_FLAGS"
ETCD_MEMBER_ID_FILE="$ETCD_DATA_DIR/member_id"
ETCD_NEW_MEMBERS_ENVS_FILE="$ETCD_DATA_DIR/new_member_envs"
ETCD_MEMBER_REMOVAL_LOG="$(dirname "$ETCD_DATA_DIR")/member_removal.log"
ETCD_ENDPOINTS_LIST="$(echo "$ETCDCTL_ENDPOINTS" | sed 's/,/ /g')"
ETCD_MEMBERS_COUNT="$(echo "$ETCD_ENDPOINTS_LIST" | wc -w)"

export ROOT_PASSWORD="${ETCD_ROOT_PASSWORD:-}"
if [ -n "${ETCD_ROOT_PASSWORD:-}" ]; then  unset ETCD_ROOT_PASSWORD; fi

log() { (>&2 echo ">>> [entrypoint.sh] $*"); }

# Store member id for later member replacement
store_member_id() {
    while ! $ETCDCTL member list; do sleep 1; done
    $ETCDCTL member list | grep "$HOSTNAME" | awk '{ print $1}' | awk -F "," '{ print $1}' > "$ETCD_MEMBER_ID_FILE"
    etcd_member_id="$(cat "$ETCD_MEMBER_ID_FILE")"
    log "Stored member id: $etcd_member_id" && exit 0
}
# Configure RBAC
configure_rbac() {
    # Only configure RBAC on the first pod
    if [ -n "${ROOT_PASSWORD:-}" ] && [ "$HOSTNAME" = "etcd-0" ]; then
        log "Configuring RBAC authentication"
        etcd &
        ETCD_PID=$!
        while ! $ETCDCTL member list; do sleep 1; done
        log "Configuring root password"
        echo "$ROOT_PASSWORD" | $ETCDCTL user add root --interactive=false
        log "Enabling auth"
        $ETCDCTL auth enable
        kill "$ETCD_PID"
        sleep 5
    fi
}

# Checks whether there was a disaster or not
is_disastrous_failure() {
    active_endpoints=0
    min_endpoints="$(((ETCD_MEMBERS_COUNT + 1)/2))"

    for e in $ETCD_ENDPOINTS_LIST; do
        if [ "$e" != "$ETCD_ADVERTISE_CLIENT_URLS" ] && (unset -v ETCDCTL_ENDPOINTS; $ETCDCTL endpoint health --endpoints="$e"); then
            active_endpoints=$((active_endpoints + 1))
        fi
    done
    log "Endpoint status: $active_endpoints/$min_endpoints (active/minimum)"
    if [ $active_endpoints -lt $min_endpoints ]; then
        log "Cluster is unhealthy"
    else
        log "Cluster is healthy"
    fi
}

delete_etcd_data_dir() {
    log "deleting etcd data dir"
    rm -rf "${ETCD_DATA_DIR:?}/*"
}

# Check wether the member was succesfully removed from the cluster
should_add_new_member() {
    return_value=1
    if grep -qE "^Member[[:space:]]+[a-z0-9]+\s+removed\s+from\s+cluster\s+[a-z0-9]+$" "$ETCD_MEMBER_REMOVAL_LOG" > /dev/null 2>&1; then
        delete_etcd_data_dir && return_value=0    
    fi

    if ! [ -d "$ETCD_DATA_DIR/member/snap" ] && ! [ -f "$ETCD_MEMBER_ID_FILE" ]; then
        delete_etcd_data_dir && return_value=0    
    fi

    rm -vf "$ETCD_MEMBER_REMOVAL_LOG"
    return $return_value
}

if [ ! -d "$ETCD_DATA_DIR" ]; then
    log "Creating data dir..."
    mkdir -vp "$ETCD_DATA_DIR"
    store_member_id &
    configure_rbac
else
    log "Detected data from previous deployments"
    is_disastrous_failure
    if should_add_new_member; then
        log "Adding new member to existing cluster"
        $ETCDCTL member add "$HOSTNAME" --peer-urls="https://${HOSTNAME}.etcd-headless.prod.svc.cluster.local:2380" | grep "^ETCD_" > "$ETCD_NEW_MEMBERS_ENVS_FILE"
        log "Loading env vars of existing cluster"
        # shellcheck source=/dev/null
        set -a && . "$ETCD_NEW_MEMBERS_ENVS_FILE" && set +a
        store_member_id &
    else
        log "Updating member in existing cluster"
        $ETCDCTL member update "$(cat "$ETCD_MEMBER_ID_FILE")" --peer-urls="https://${HOSTNAME}.etcd-headless.prod.svc.cluster.local:2380"
    fi
fi
# shellcheck disable=SC2086
exec etcd $ETCD_FLAGS
