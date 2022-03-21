#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=${1:-true}
DELETE_THRESHOLD=$(date --date="7 days ago" --iso-8601=seconds --utc)
PIPELINERUNS=$(kubectl get pipelinerun -ojson -A)

echo "$PIPELINERUNS" | \
 jq -r -c '.items[] | select(.status.conditions[0]?.reason == "Failed") | select(.status.completionTime < "'${DELETE_THRESHOLD}'") | [.metadata.namespace, .metadata.name] | @tsv' | \
   while read line; do
     namespace=$(echo "$line"| awk '{ print $1 }')
     name=$(echo "$line"| awk '{ print $2 }')

     echo "[+] deleting pipelinerun: namespace=$namespace, name=$name"
     if [[ "$DRY_RUN" == "false" ]]; then
       kubectl -n "$namespace" delete pipelinerun "$name" --ignore-not-found
     fi
   done
