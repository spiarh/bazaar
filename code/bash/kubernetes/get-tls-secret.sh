#!/usr/bin/env bash

NAMESPACE="$1"
SECRET_NAME="$2"
BASE_FILENAME="${NAMESPACE}_${SECRET_NAME}"

secret_json="$(kubectl -n "$NAMESPACE" get secrets "$SECRET_NAME" -ojson)"

crt=$(echo "$secret_json" | jq -r '.data["tls.crt"]' | base64 -d -w0)
key=$(echo "$secret_json" | jq -r '.data["tls.key"]' | base64 -d -w0)
ca_crt=$(echo "$secret_json" | jq -r '.data["ca.crt"]' | base64 -d -w0)

echo "$crt" > "${BASE_FILENAME}_tls.crt"
echo "$key" > "${BASE_FILENAME}_tls.key"
echo "$ca_crt" > "${BASE_FILENAME}_ca.crt"
