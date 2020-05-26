#!/usr/bin/env bash
LB_ENDPOINT="aa-lb.caasp.suse.net"
OLD_PORT="6443"
NEW_PORT="5443"
OLD_ENDPOINT="$LB_ENDPOINT:$OLD_PORT"
NEW_ENDPOINT="$LB_ENDPOINT:$NEW_PORT"
NAMESPACES="kubectl get ns -ojsonpath='{.items[*].metadata.name}'"

function update_cm() {
  local cm
  local ns
  cm="$1"
  ns="$2"
  echo ">>> Updating ConfigMap $cm in $ns Namespace"
  kubectl -n "$ns" get cm "$cm" -oyaml | sed "s/$OLD_ENDPOINT/$NEW_ENDPOINT/g" | kubectl apply -f -
}

for f in bootstrap-kubelet admin controller scheduler kubelet controller-manager; do
  conf="/etc/kubernetes/$f.conf"
  if [[ -f "$conf" ]]; then
    if grep "$OLD_ENDPOINT" "$conf"; then
      echo ">>> Updating configuration file $conf with new lb port"
      sed -i "s/$OLD_ENDPOINT/$NEW_ENDPOINT/g" "$conf"
      systemctl restart kubelet
    else
      echo ">>> Configuration file $conf already use the new lb port"
    fi
  fi
done

for f in "scheduler" "controller-manager"; do
  ctn="$(crictl ps --name "kube-$f" -q)"
  if [[ $ctn != "" ]]; then
    if crictl exec "$ctn" sh -c "cat /etc/kubernetes/$f.conf | grep $OLD_PORT" > /dev/null 2>&1; then
      echo ">>> deleting container kube-$f"
      crictl rm -f "$ctn"
    else
      echo ">>> container kube-$f already uses the new port"
    fi
  fi
done

for ns in $NAMESPACES; do
  for cm in $(kubectl -n "$ns" get cm -ojsonpath='{.items[*].metadata.name}'); do
    update_cm "$cm" "$ns"
  done
done
