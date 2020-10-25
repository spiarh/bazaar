#!/usr/bin/env bash

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )/secrets"
mkdir -p "$DIR"

HOSTS="$(ansible -i ./inventory.yml 'all,!lxd_k8s*' --list-hosts | grep -v '^.*hosts')"

# Wireguard
WG_DIR="$DIR/wireguard"
PRESHARED_KEY="$WG_DIR/preshared_key"

# Kubernetes
DEFAULT_CN="kubearnetes.com"
KUBEADM_DIR="$DIR/kubeadm"
PKI_DIR="$DIR/pki"
PKI_ETCD_DIR="$DIR/pki/etcd"
KUBEADM_TOKEN="$KUBEADM_DIR/token"
KUBEADM_CA_CERT_HASH="$KUBEADM_DIR/ca_cert_hash"
DEFAULT_CA_BASENAME="$PKI_DIR/ca"
ETCD_CA_BASENAME="$PKI_ETCD_DIR/ca"
FRONT_PROXY_CA_BASENAME="$PKI_DIR/front-proxy-ca"
SA_KEY="$PKI_DIR/sa.key"
SA_PUB="$PKI_DIR/sa.pub"

function log() {
  echo ">>> [misc] $*"
}

function log_vault() {
  echo ">>> [vault] $*"
}

function log_wg() {
  echo ">>> [wireguard] $*"
}

function log_pki() {
  echo ">>> [pki] $*"
}

function log_kubeadm() {
  echo ">>> [kubeadm] $*"
}

function ansible_vault() {
  local filepath
  filepath="$1"

  if head -n1 "$filepath" | grep -v ANSIBLE_VAULT > /dev/null 2>&1; then
    log_vault "encrypting with ansible-vault, $filepath"
    ansible-vault encrypt --vault-password-file "$filepath"
    chmod 0400 "$filepath"
  else
    log_vault "file already encrypted with ansible-vault, $filepath"
  fi
}

function create_ca() {
  local basename
  local key
  local crt

  basename="$1"
  key="$basename.key"
  crt="$basename.crt"

  if ! [[ -f "$key" ]] && ! [[ -f "$crt" ]]; then
    log_pki "generate key, $key"
    openssl genrsa -out "$key" 2048
    log_pki "generate crt, $crt"
    openssl req -x509 -new -nodes -key "$key" -subj "/CN=$DEFAULT_CN" -days 3650 -out "$crt"
  else
    log_pki "key already exists, $key"
    log_pki "crt already exists, $crt"
  fi
}

log "manage local dirs"
mkdir -pv "$WG_DIR" "$KUBEADM_DIR" "$PKI_DIR" "$PKI_ETCD_DIR"

if ! hash wg > /dev/null 2>&1; then
  log_wg "'wg' cmd not available" && exit 1
fi

# wireguard pre-shared key
if ! [[ -f "$PRESHARED_KEY" ]]; then
  log_wg "generate pre-shared key"
  wg genpsk > "$PRESHARED_KEY"
  ansible_vault "$PRESHARED_KEY"
  chmod 0400 "$PRESHARED_KEY"
else
  log_wg "pre-shared key exists, $PRESHARED_KEY"
fi
echo""

# wireguard keys
for h in $HOSTS; do
  log_wg "Generate keys for $h"
  priv_key="$WG_DIR/$h/priv_key"
  pub_key="$WG_DIR/$h/pub_key"

  mkdir -pv "$WG_DIR/$h"
  if ! [[ -f "$priv_key" ]]; then
    log_wg "generate private key, $priv_key"
    wg genkey > "$priv_key"
  else
    log_wg "private key exists, $priv_key"
  fi

  if ! [[ -f "$pub_key" ]]; then
    log_wg "generate public key, $pub_key"
    wg pubkey < "$priv_key" > "$pub_key"
  else
    log_wg "public key exists, $pub_key"
  fi

  for k in $priv_key $pub_key; do
      ansible_vault "$k"
  done
  echo -e "\n"
done

# ca
for name in "$DEFAULT_CA_BASENAME" "$ETCD_CA_BASENAME" "$FRONT_PROXY_CA_BASENAME"; do
  create_ca "$name"
done

# service-account
if ! [[ -f "$SA_KEY" ]] && ! [[ -f "$SA_PUB" ]]; then
  log_pki "generate service-account key, $SA_KEY"
  openssl genrsa -out "$SA_KEY" 2048
  log_pki "generate service-account pubkey, $SA_PUB"
  openssl rsa -in "$SA_KEY" -pubout > "$SA_PUB"
else
  log_pki "service-account key exists, $SA_KEY"
  log_pki "service-account pubkey exists, $SA_PUB"
fi

# kubeadm token
if ! [[ -f "$KUBEADM_TOKEN" ]]; then
  log_kubeadm "generate token, $KUBEADM_TOKEN"
  echo "$(openssl rand -hex 3).$(openssl rand -hex 8)"  > "$KUBEADM_TOKEN"
  ansible_vault "$KUBEADM_TOKEN"
else
  log_kubeadm "token exists, $KUBEADM_TOKEN"
fi

# ca cert hash
if ! [[ -f "$KUBEADM_CA_CERT_HASH" ]]; then
  if [[ -f "$DEFAULT_CA_BASENAME.crt" ]]; then
    log_kubeadm "default ca exists, $DEFAULT_CA_BASENAME.crt"
    log_kubeadm "generate ca cert hash, $KUBEADM_CA_CERT_HASH"
    openssl x509 -pubkey -in "$DEFAULT_CA_BASENAME.crt" | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > "$KUBEADM_CA_CERT_HASH"
    ansible_vault "$KUBEADM_CA_CERT_HASH"
  else
    log_kubeadm "can not create ca cert hash because default ca does not exist, $DEFAULT_CA_BASENAME.crt"
  fi
else
  log_kubeadm "ca cert hash already exists, $KUBEADM_CA_CERT_HASH"
fi

# encrypt everything
# shellcheck disable=SC2044
for f in $(find "$PKI_DIR" -type f); do
  ansible_vault "$f"
done
