#!/usr/bin/env bash

IFS=$'\n'
KIND="newrelicmonitors"
NRMS=$(oc get $KIND --no-headers --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name 2>&1)

if echo "$NRMS" | grep -q "error: the server doesn't have a resource type"; then
    echo "No $KIND resource found, exiting..." && exit 0
fi

for nrm in $NRMS; do
    ns=$(echo "$nrm" | awk '{print $1}')
    rsc=$(echo "$nrm" | awk '{print $2}')
    oc patch -n "$ns" "$KIND/$rsc" -p '{"metadata":{"finalizers": []}}' --type=merge
    oc delete -n "$ns" "$KIND/$rsc" --ignore-not-found=true
done
