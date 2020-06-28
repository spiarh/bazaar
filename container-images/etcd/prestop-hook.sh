#!/bin/sh

set -o errexit
set -o nounset

# Constants
AUTH_OPTIONS="--user root:$ETCD_ROOT_PASSWORD --cert=$ETCD_CERT_FILE --key=$ETCD_KEY_FILE --cacert=$ETCD_TRUSTED_CA_FILE --insecure-skip-tls-verify"

etcdctl $AUTH_OPTIONS member remove --debug=true "$(cat "$ETCD_DATA_DIR/member_id")" > "$(dirname "$ETCD_DATA_DIR")/member_removal.log" 2>&1
