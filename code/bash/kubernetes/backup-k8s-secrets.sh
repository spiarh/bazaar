#!/usr/bin/env bash

SECRETS_DIR="./secrets"
NAMESPACES=$(kubectl get ns -ojsonpath='{.items[*].metadata.name}')

for ns in $NAMESPACES; do
  mkdir -p "$SECRETS_DIR/$ns"
  secrets=$(kubectl -n "$ns" get secrets -ojsonpath='{.items[*].metadata.name}')
  for s in $secrets; do
    kubectl -n "$ns" get secret "$s" -oyaml > "$SECRETS_DIR/$ns/$s.yaml"
  done
done
