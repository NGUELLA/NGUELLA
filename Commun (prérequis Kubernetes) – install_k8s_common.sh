#!/bin/bash
set -e

# Branche stable à utiliser (adapter au besoin)
K8S_MINOR="v1.34"

echo "[INFO] Mise à jour du système..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "[INFO] Installation des dépendances Kubernetes..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg lsb-release

echo "[INFO] Préparation du répertoire de clés..."
sudo mkdir -p -m 755 /etc/apt/keyrings

echo "[INFO] Ajout de la clé GPG Kubernetes..."
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "[INFO] Ajout du dépôt Kubernetes..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "[INFO] Installation kubelet / kubeadm / kubectl..."
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Désactivation du swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "[INFO] Configuration des modules noyau..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "[INFO] Configuration sysctl pour Kubernetes..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

echo "[INFO] Prérequis Kubernetes installés (branche ${K8S_MINOR})."
