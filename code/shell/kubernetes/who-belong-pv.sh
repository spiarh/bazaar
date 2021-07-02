#!/usr/bin/env bash

# owners == namespace

pv=$(kubectl get pv -ojson)
# shellcheck disable=SC2002
owners=$(echo "$pv" | jq -r '.items[] | .spec.claimRef.namespace' | awk -F '--' '{ print $1 }')

echo ">>> Number of pv per namespace"
echo "$owners" | sort | uniq -c | awk '{printf "%02d %s\n", $1, $2}' | sort -nr

echo 
echo ">>> Alphabetical order"
echo "$owners" | sort | uniq -c | awk '{printf "%s %02d\n", $2, $1}' | sort -nr
