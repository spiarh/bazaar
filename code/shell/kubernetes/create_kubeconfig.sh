#!/usr/bin/env bash

# Create SA
APISERVER="https://aa-lb.caasp.suse.net:5443"
CLUSTER_NAME="prod-cluster"
NAMESPACE="default"
SA_NAME="capteam-admin"
CLUSTER_ROLE="cluster-admin"
TOKEN_NAME="$SA_NAME-secret-token"

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SA_NAME
  namespace: $NAMESPACE
secrets:
- name: $TOKEN_NAME
---
apiVersion: v1
kind: Secret
metadata:
  name: $TOKEN_NAME
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: $SA_NAME
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $SA_NAME-clusterrole-binding
roleRef:
  kind: ClusterRole
  name: $CLUSTER_ROLE
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: $SA_NAME
  namespace: $NAMESPACE
EOF


cat > new_kubeconfig <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $(kubectl -n $NAMESPACE get secret $TOKEN_NAME -o "jsonpath={.data['ca\.crt']}")
    server: $APISERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: $SA_NAME
  name: $SA_NAME@$CLUSTER_NAME
current-context: $SA_NAME@$CLUSTER_NAME
kind: Config
preferences: {}
users:
- name: $SA_NAME
  user:
    token: $(kubectl -n $NAMESPACE get secret $TOKEN_NAME -o "jsonpath={.data['token']}" | base64 -d -w0)
EOF
