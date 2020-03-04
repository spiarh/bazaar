#!/usr/bin/env bash
set -euo pipefail

# k8s 1.14
#SKUBA_TAG="product-0.4.0-1.1"

# GMC
#SKUBA_TAG="product-1.0.2-1.1"

LOG_LEVEL="8"
CLUSTER_NAME="my-cluster"
KUBECONFIG="$PWD/$CLUSTER_NAME/admin.conf"
KUBECTL="kubectl --kubeconfig=$KUBECONFIG"

USAGE=$(cat <<USAGE
Usage:

--deploy
--redeploy

--tapply
--tdestroy
--tout
--tplan
--tredeploy (destroy + apply)

--sdeploy
--sdeploy-masters
--sdeploy-workers
--sstatus

--updates <target> <action>
    --updates all disable

--reboots <action>
    --reboots enable

--install-suse-ca

--add-repo <target> <env>
    --add-repo masters devel
    --add-repo masters staging
    --add-repo workers product
    --add-repo all update

--node-upgrade <mode> <target> <action>
    --node-upgrade aggressive all plan
    --node-upgrade safe masters apply
    --node-upgrade safe workers apply

--scp-to <target> <src> <dst> 
    all ./passwd /tmp/passwd

--scp-from <target> <src> <dst> 
    all /etc/passwd ./passwd

--show-images

--run-cmd "sudo ..."
USAGE
)

log()        { (>&2 echo -e ">>> [skuba-manage] ($(date '+%Y-%m-%d %H:%M:%S')) $@"); }

get_vm_from_terraform_output() {
  if [[ -f "./terraform.tfstate" ]]; then
    JSON=$(terraform output -json)
    if [[ "$JSON" != "{}" ]]; then
        LB=$(echo "$JSON" | jq -r '.ip_load_balancer.value[]')
        MASTERS="$(echo "$JSON" | jq -r '.ip_masters.value | to_entries[] | join (":")')"
        WORKERS="$(echo "$JSON" | jq -r '.ip_workers.value | to_entries[] | join (":")')"
        ALL="$MASTERS $WORKERS"
    fi
  fi
}

clear_cluster_deployment() {
  if [[ -d "$CLUSTER_NAME" ]]; then
    rm -Rfv "$CLUSTER_NAME.backup"
    mv "$CLUSTER_NAME" "$CLUSTER_NAME.backup"
    rm -Rfv "$CLUSTER_NAME"
  fi
}

new_line() {
  echo -e ""
}

skuba() {
  local app_path="$PWD/$CLUSTER_NAME"
  # if 'skuba cluster init'
  if [[ "$2" == "init" ]]; then
      local app_path="$PWD"
  fi

  podman run -ti --rm \
  -v "$app_path":/app \
  -v "$(dirname "$SSH_AUTH_SOCK")":"$(dirname "$SSH_AUTH_SOCK")" \
  -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
  "skuba:$SKUBA_TAG" "$@"
  #-u "$(id -u)":"$(id -g)" \
}

ssh2() {
  local host=$1
  shift
  ssh -o UserKnownHostsFile=/dev/null \
      -o StrictHostKeyChecking=no \
      -F /dev/null \
      -o LogLevel=ERROR \
      "sles@$host" "$@"
}

reboots() {
#kubectl -n kube-system patch ds kured -p '{"spec":{"template":{"metadata":{"labels":{"name":"kured"}},"spec":{"containers":[{"name":"kured","command":["/usr/bin/kured", "--period=10s"]}]}}}}'
  local action="$1"
  if [[ "$action" == "disable" ]]; then
    log "Disabling node reboots in kured"
    $KUBECTL -n kube-system annotate ds kured weave.works/kured-node-lock='{"nodeID":"manual"}'
  else
    log "Enabling node reboots in kured"
    $KUBECTL -n kube-system annotate ds kured weave.works/kured-node-lock-
  fi
}

run_cmd() {
  define_node_group "$1"
  CMD="$2"
  for n in $GROUP; do
    echo "$n"
      get_ip_nodename "$n"
      log "Running '$CMD' on $n"
      ssh2 "$IP" "$CMD" || echo "run-cmd failed" && /bin/true
      #(ssh2 "$n" "$CMD" || echo "run-cmd failed" && /bin/true) &
      #sleep 0.5
  done
}

use_scp() {
  define_node_group "$1"
  SRC="$2"
  DEST="$3"
  TYPE="$4"
  local options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -F /dev/null -o LogLevel=ERROR -r"

  for n in $GROUP; do
    get_ip_nodename "$n"
    if [[ "$TYPE" == "to" ]]; then
      log "SCP-TO '$SRC' to '$DEST' on $n"
      scp $options "$SRC" "sles@$IP:$DEST"
    fi
    if [[ "$TYPE" == "FROM" ]]; then
      log "SCP-FROM '$SRC' to '$DEST' from $n"
      scp $options "sles@$IP:$SRC" "$DEST"
    fi
  done
}

show_images() {
  $KUBECTL get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s ':space:' '\n'
}

updates() {
  define_node_group "$1"
  local action="$2"
  for n in $GROUP; do
      get_ip_nodename "$n"
      log "$action skuba-update on $n"
      ssh2 "$IP" "sudo systemctl $action --now skuba-update.timer"
  done
}

install_suse_ca() {
  for n in $1; do
      get_ip_nodename "$n"
      log "Installing SUSE CA on $n"
      ssh2 "$IP" "if ! zypper lr SUSE_CA > /dev/null 2>&1; then sudo zypper ar -f http://download.suse.de/ibs/SUSE:/CA/SLE_15_SP1/SUSE:CA.repo; fi"
      ssh2 "$IP" "if ! rpm -q ca-certificates-suse > /dev/null 2>&1; then sudo zypper in -y ca-certificates-suse; sudo systemctl restart crio || /bin/true; fi"
  done
}

add_repo() {
  local repo_env="$2"
  if [[ "$repo_env" == "devel" ]]; then local repo="http://download.suse.de/ibs/Devel:/CaaSP:/4.0/SLE_15_SP1/"; fi
  if [[ "$repo_env" == "staging" ]]; then local repo="http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40/staging/"; fi
  if [[ "$repo_env" == "product" ]]; then local repo="http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40/standard/"; fi
  if [[ "$repo_env" == "update" ]]; then local repo="http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40:/Update/standard/"; fi
  
  local target="$1"
  define_node_group "$target"
  
  for n in $GROUP; do
      get_ip_nodename "$n"
      log "Adding repo $repo_env on $n"
      ssh2 "$IP" "if ! zypper lr $repo_env > /dev/null 2>&1; then sudo zypper ar -f $repo $repo_env; fi"
  done
}

init_control_plane() {
  if ! [[ -d "$CLUSTER_NAME" ]]; then
      log "Deploying control plane"
      skuba cluster init --control-plane "$LB" "$CLUSTER_NAME"
  fi
}

get_ip_nodename() {
   NODE_NAME="$(echo $1|awk -F":" '{ print $1 }')"
   IP="$(echo $1|awk -F":" '{ print $2 }')"
}

deploy_masters() {
local i=0
for n in $1; do
    #local j="$(printf "%03g" $i)"
    get_ip_nodename "$n"
    if [[ $i -eq 0 ]]; then
      log "Boostrapping first master node, $n"
      skuba node bootstrap --user sles --sudo --target "$IP" "$NODE_NAME" -v "$LOG_LEVEL"
    fi

    if [[ $i -ne 0 ]]; then
      log "Boostrapping other master nodes, $n"
      skuba node join --role master --user sles --sudo --target  "$IP" "$NODE_NAME" -v "$LOG_LEVEL"
    fi
    ((++i))
done
}

deploy_workers() {
  local i=0
  for n in $1; do
    #local j="$(printf "%03g" $i)"
    get_ip_nodename "$n"
    log "Deploying workers, $n"
    (skuba node join --role worker --user sles --sudo --target  "$IP" "$NODE_NAME" -v "$LOG_LEVEL") &
    sleep 3
    ((++i))
  done
}

sstatus() {
  skuba cluster status
}

sdeploy() {
  clear_cluster_deployment
  get_vm_from_terraform_output
  init_control_plane
  deploy_masters "$MASTERS"
  deploy_workers "$WORKERS"
}

sdeploy_masters() {
  deploy_masters "$MASTERS"
}

sdeploy_workers() {
  deploy_workers "$WORKERS"
}

define_node_group() {
  case "$1" in
    "all")
    GROUP="$ALL"
    ;;
    "masters")
    GROUP="$MASTERS"
    ;;
    "workers")
    GROUP="$WORKERS"
    ;;
    *)
    GROUP="$1"
    ;;
  esac
}

node_upgrade() {
  local mode="$1"
  define_node_group "$2"
  local action="$3"

  local i=0
  for n in $GROUP; do
    get_ip_nodename "$n"
    #local node_name="$($KUBECTL get nodes  -o json | jq ".items[] | {name: .metadata.name, ip: .status.addresses[] | select(.type==\"InternalIP\") | select(.address==\"$n\")}" | jq -r '.name')"
    if [[ "$action" = "plan" ]]; then
      log "Planning upgrade on $NODE_NAME, $n"
      skuba node upgrade plan "$NODE_NAME" -v "$LOG_LEVEL" 
    fi  

    if [[ "$action" = "apply" ]]; then
      log "Upgrading node $n"

      if ! skuba node upgrade plan "$NODE_NAME" -v "$LOG_LEVEL" | grep "Node $NODE_NAME is up to date"; then
        if [[ "$mode" == "safe" ]]; then
          log "Draining node $n"
          date
          kubectl get po -A --field-selector spec.nodeName="$NODE_NAME"
          kubectl drain "$NODE_NAME" --grace-period=600 --timeout=900s --ignore-daemonsets --delete-local-data
        fi

        skuba node upgrade apply --user sles --sudo --target "$IP" -v "$LOG_LEVEL" 

        if [[ "$mode" == "safe" ]]; then
          log "Sleep 1 min as a workaround for the crio panic version bug..."
          sleep 60
          log "Uncordoning $NODE_NAME"
          kubectl uncordon "$NODE_NAME"
        fi
      fi
    fi

    if [[ "$action" = "fake" ]]; then
      log "Running fake upgrade on node $n"
      log "Draining node $n"
      kubectl get po -A --field-selector spec.nodeName="$NODE_NAME"
      kubectl drain "$NODE_NAME" --grace-period=600 --timeout=900s --ignore-daemonsets --delete-local-data

      log "Restart crio and Kubelet"
      run_cmd "$IP" "sudo systemctl stop crio kubelet && sudo systemctl start crio kubelet"

      log "Sleep 2 min as if it was an upgrade"
      sleep 120

      log "Uncordoning $NODE_NAME"
      kubectl uncordon "$NODE_NAME"
    fi
    new_line
  done
}

is_reachable() {
  define_node_group "$1"

  local i=0
  for n in $GROUP; do
    get_ip_nodename "$n"
    log "Pinging $n"
    if ping -c1 -W2 "$IP" > /dev/null 2>&1; then
      echo "YES"
    else
      echo "NOOOOOOOOOOOOO"
    fi
    new_line
  done
}

tapply() {
  terraform apply -parallelism=1 -auto-approve "$@"
}

tdestroy() {
  terraform destroy -auto-approve "$@"
  clear_cluster_deployment
}

toutput() {
  terraform output "$@"
}

tplan() {
  log "Running terraform plan"
  terraform plan
}

tredeploy() {
  tdestroy
  tapply
}

deploy() {
  tapply
  sdeploy
}

redeploy() {
  tredeploy
  sdeploy
}

get_vm_from_terraform_output

# Parse options
while [[ $# -gt 0 ]] ; do
    case $1 in
    --tapply)
      shift
      tapply "$@"
      ;;
    --tdestroy)
      shift
      tdestroy "$@"
      ;;
    --tout)
      shift
      toutput "$@"
      ;;
    --tplan)
      tplan
      ;;
    --tredeploy)
      tredeploy
      ;;
    --sdeploy)
      sdeploy
      ;;
    --sdeploy-masters)
      sdeploy_masters
      ;;
    --sdeploy-workers)
      sdeploy_workers
      ;;
    --sstatus)
      sstatus
      ;;
    --deploy)
      deploy
      ;;
    --redeploy)
      redeploy
      ;;
    --node-upgrade)
      MODE="${2}"
      TARGET="${3}"
      ACTION="${4}"
      node_upgrade "$MODE" "$TARGET" "$ACTION"
      ;;
    --is-reachable)
      TARGET="$2"
      is_reachable "$TARGET"
      ;;
    --test)
      TARGET="$2"
      my_test "$TARGET"
      ;;
    --updates)
      TARGET="${2}"
      ACTION="${3}"
      updates "$TARGET" "$ACTION"
      ;;
    --reboots)
      ACTION="${2}"
      reboots "$ACTION"
      ;;
    --install-suse-ca)
      install_suse_ca "$ALL"
      ;;
    --add-repo)
      TARGET="${2}"
      REPO="$3"
      add_repo "$TARGET" "$REPO"
      ;;
    --run-cmd)
      TARGET="${2}"
      CMD="$3"
      run_cmd "$TARGET" "$CMD"
      ;;
    --scp-from)
      TARGET="${2}"
      SRC="$3"
      DEST="$4"
      TYPE="from"
      use_scp "$TARGET" "$SRC" "$DEST" "$TYPE"
      ;;
    --scp-to)
      TARGET="${2}"
      SRC="$3"
      DEST="$4"
      TYPE="to"
      use_scp "$TARGET" "$SRC" "$DEST" "$TYPE"
      ;;
    --show-images)
      show_images
      ;;
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
  esac
  shift
done
