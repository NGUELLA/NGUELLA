#!/bin/bash
set -e

POD_CIDR="10.244.0.0/16"

echo "[INFO] Initialisation du master Kubernetes..."
sudo kubeadm init --pod-network-cidr=${POD_CIDR}

echo "[INFO] Configuration du contexte kubectl pour l'utilisateur courant..."
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo "[INFO] Déploiement du réseau Calico..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

echo
echo "[INFO] Cluster master initialisé."
echo "[INFO] Récupère la commande 'kubeadm join' affichée à la fin de kubeadm init"
echo "      et exécute-la sur chaque worker."
