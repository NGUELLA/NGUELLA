#!/bin/bash
set -e

# Remplacer la ligne ci-dessous par la commande join complète copiée depuis le master
KUBEADM_JOIN_COMMAND="sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>"

echo "[INFO] Jointure du worker au cluster..."
eval "$KUBEADM_JOIN_COMMAND"

echo "[INFO] Worker joint au cluster Kubernetes."
