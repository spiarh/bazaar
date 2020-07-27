#!/bin/sh

set -o errexit
set -o nounset

AUTH_SKIP_TLS="${AUTH_SKIP_TLS:-false}"
AUTH_SKIP_TLS_FLAG=""
if [ "${AUTH_SKIP_TLS}" = "true" ]; then AUTH_SKIP_TLS_FLAG="--insecure-skip-tls-verify"; fi
AUTH_OPTIONS="--user root:$ETCD_ROOT_PASSWORD $AUTH_SKIP_TLS_FLAG"

etcdctl $AUTH_OPTIONS member remove --debug=true "$(cat "$ETCD_DATA_DIR/member_id")" > "$(dirname "$ETCD_DATA_DIR")/member_removal.log" 2>&1
