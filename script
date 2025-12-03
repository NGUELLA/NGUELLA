#!/bin/bash

################################################################################
# SCRIPT COMPLET DE CLONAGE INFRASTRUCTURE DEVOPS
# Clone: Jenkins (jobs+pipelines+credentials) + Nexus + SonarQube + Docker + K8s
# Adapté à votre infrastructure (VM1 master)
# Auteur: DevOps Script
# Date: 2025-12-03
################################################################################

set -e

# ======================== COULEURS ========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ======================== CONFIGURATION ========================
BACKUP_DIR="/backup/devops_complet"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BACKUP_DIR}/clone_${TIMESTAMP}.log"
JENKINS_HOME="/var/lib/jenkins"
NEXUS_VOLUME="/var/lib/docker/volumes/c9aaf94d9461ed357dee2e4a88663936d81e36e12580495d9260a8265ea2b922/_data"
SONARQUBE_VOLUME="/opt/sonarqube/data"

# ======================== FONCTIONS UTILITAIRES ========================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1" >> "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "${LOG_FILE}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en ROOT (sudo)"
        exit 1
    fi
}

################################################################################
# SECTION 1: SAUVEGARDE COMPLÈTE
################################################################################

backup_complete() {
    log_info "================================================"
    log_info "DÉBUT SAUVEGARDE COMPLÈTE DE L'INFRASTRUCTURE"
    log_info "================================================"
    
    mkdir -p "${BACKUP_DIR}"
    
    # ============ 1. JENKINS (jobs + pipelines + credentials) ============
    log_info "[1/8] Sauvegarde JENKINS (jobs, pipelines, credentials)..."
    mkdir -p "${BACKUP_DIR}/jenkins"
    
    if [ -d "${JENKINS_HOME}" ]; then
        # Sauvegarder TOUT le JENKINS_HOME
        cp -a "${JENKINS_HOME}/jobs" "${BACKUP_DIR}/jenkins/" 2>/dev/null || true
        cp -a "${JENKINS_HOME}/secrets" "${BACKUP_DIR}/jenkins/" 2>/dev/null || true
        cp -a "${JENKINS_HOME}/plugins" "${BACKUP_DIR}/jenkins/" 2>/dev/null || true
        cp -a "${JENKINS_HOME}/users" "${BACKUP_DIR}/jenkins/" 2>/dev/null || true
        cp -a "${JENKINS_HOME}/config.xml" "${BACKUP_DIR}/jenkins/" 2>/dev/null || true
        cp -a "${JENKINS_HOME}/credentials.xml" "${BACKUP_DIR}/jenkins/" 2>/dev/null || true
        cp -a "${JENKINS_HOME}/hudson.tasks.Shell.xml" "${BACKUP_DIR}/jenkins/" 2>/dev/null || true
        
        # Lister la structure
        find "${JENKINS_HOME}/jobs" -type f -name "config.xml" > "${BACKUP_DIR}/jenkins/jobs_list.txt" 2>/dev/null || true
        
        log_success "Jenkins sauvegardé ($(du -sh ${BACKUP_DIR}/jenkins | cut -f1))"
    else
        log_warning "Jenkins Home ${JENKINS_HOME} non trouvé"
    fi
    
    # ============ 2. NEXUS (données + repositories + artifacts) ============
    log_info "[2/8] Sauvegarde NEXUS (repositories, artifacts, configs)..."
    mkdir -p "${BACKUP_DIR}/nexus"
    
    if [ -d "${NEXUS_VOLUME}" ]; then
        cp -a "${NEXUS_VOLUME}" "${BACKUP_DIR}/nexus/nexus-data" 2>/dev/null || true
        log_success "Nexus sauvegardé ($(du -sh ${BACKUP_DIR}/nexus | cut -f1))"
    else
        log_warning "Volume Nexus ${NEXUS_VOLUME} non trouvé - essai accès Docker..."
        docker cp nexus:/nexus-data "${BACKUP_DIR}/nexus/" 2>/dev/null || log_warning "Copie Nexus Docker échouée"
    fi
    
    # ============ 3. SONARQUBE (projets + analyses + qualité) ============
    log_info "[3/8] Sauvegarde SONARQUBE (projets, analyses, qualité)..."
    mkdir -p "${BACKUP_DIR}/sonarqube"
    
    # SonarQube utilise volumes internes Docker (mounts vides), copier depuis le conteneur
    docker cp sonar:/opt/sonarqube/data "${BACKUP_DIR}/sonarqube/" 2>/dev/null || true
    docker cp sonar:/opt/sonarqube/extensions "${BACKUP_DIR}/sonarqube/" 2>/dev/null || true
    docker cp sonar:/opt/sonarqube/conf "${BACKUP_DIR}/sonarqube/" 2>/dev/null || true
    
    log_success "SonarQube sauvegardé ($(du -sh ${BACKUP_DIR}/sonarqube | cut -f1))"
    
    # ============ 4. DOCKER (images + configurations) ============
    log_info "[4/8] Sauvegarde DOCKER (images, configurations)..."
    mkdir -p "${BACKUP_DIR}/docker"
    
    cp -r /etc/docker "${BACKUP_DIR}/docker/config" 2>/dev/null || true
    
    # Exporter images critiques
    log_info "    → Export image Jenkins..."
    docker save jenkins/jenkins:latest -o "${BACKUP_DIR}/docker/jenkins_latest.tar" 2>/dev/null || true
    
    log_info "    → Export image SonarQube..."
    docker save sonarqube:lts-community -o "${BACKUP_DIR}/docker/sonarqube_lts.tar" 2>/dev/null || true
    
    log_info "    → Export image Nexus..."
    docker save sonatype/nexus3:latest -o "${BACKUP_DIR}/docker/nexus3_latest.tar" 2>/dev/null || true
    
    # Lister toutes les images
    docker images > "${BACKUP_DIR}/docker/images_list.txt" 2>/dev/null || true
    docker ps -a > "${BACKUP_DIR}/docker/containers_list.txt" 2>/dev/null || true
    
    log_success "Docker sauvegardé ($(du -sh ${BACKUP_DIR}/docker | cut -f1))"
    
    # ============ 5. KUBERNETES MASTER (configs + état + manifests) ============
    log_info "[5/8] Sauvegarde KUBERNETES MASTER (configs, état, manifests)..."
    mkdir -p "${BACKUP_DIR}/kubernetes"
    
    cp -a /etc/kubernetes "${BACKUP_DIR}/kubernetes/etc-kubernetes" 2>/dev/null || true
    
    mkdir -p "${BACKUP_DIR}/kubernetes/kubeconfig"
    cp ~/.kube/config "${BACKUP_DIR}/kubernetes/kubeconfig/" 2>/dev/null || true
    cp /root/.kube/config "${BACKUP_DIR}/kubernetes/kubeconfig/root_config" 2>/dev/null || true
    
    # Exporter TOUS les manifests et états
    mkdir -p "${BACKUP_DIR}/kubernetes/manifests"
    kubectl get all -A -o yaml > "${BACKUP_DIR}/kubernetes/manifests/all_resources.yaml" 2>/dev/null || true
    kubectl get pvc -A -o yaml > "${BACKUP_DIR}/kubernetes/manifests/pvcs.yaml" 2>/dev/null || true
    kubectl get pv -o yaml > "${BACKUP_DIR}/kubernetes/manifests/pvs.yaml" 2>/dev/null || true
    kubectl get nodes -o yaml > "${BACKUP_DIR}/kubernetes/manifests/nodes.yaml" 2>/dev/null || true
    kubectl get configmap -A -o yaml > "${BACKUP_DIR}/kubernetes/manifests/configmaps.yaml" 2>/dev/null || true
    kubectl get secret -A -o yaml > "${BACKUP_DIR}/kubernetes/manifests/secrets.yaml" 2>/dev/null || true
    kubectl get ingress -A -o yaml > "${BACKUP_DIR}/kubernetes/manifests/ingress.yaml" 2>/dev/null || true
    kubectl get networkpolicy -A -o yaml > "${BACKUP_DIR}/kubernetes/manifests/networkpolicies.yaml" 2>/dev/null || true
    
    # Backup etcd (si local)
    if [ -d "/var/lib/etcd" ]; then
        log_info "    → Sauvegarde etcd..."
        cp -a /var/lib/etcd "${BACKUP_DIR}/kubernetes/" 2>/dev/null || true
    fi
    
    log_success "Kubernetes sauvegardé ($(du -sh ${BACKUP_DIR}/kubernetes | cut -f1))"
    
    # ============ 6. CONFIGURATIONS RÉSEAU ============
    log_info "[6/8] Sauvegarde configurations RÉSEAU..."
    mkdir -p "${BACKUP_DIR}/network"
    
    cp -a /etc/netplan "${BACKUP_DIR}/network/" 2>/dev/null || true
    cp /etc/hostname "${BACKUP_DIR}/network/" 2>/dev/null || true
    cp /etc/hosts "${BACKUP_DIR}/network/" 2>/dev/null || true
    cp /etc/resolv.conf "${BACKUP_DIR}/network/" 2>/dev/null || true
    
    log_success "Configurations réseau sauvegardées"
    
    # ============ 7. MÉTADONNÉES ET VERSIONS ============
    log_info "[7/8] Sauvegarde MÉTADONNÉES et VERSIONS..."
    mkdir -p "${BACKUP_DIR}/metadata"
    
    cat > "${BACKUP_DIR}/metadata/versions.txt" << 'EOF'
================================================================================
VERSIONS INFRASTRUCTURE DEVOPS - Sauvegarde
================================================================================
EOF
    
    echo "Date: $(date)" >> "${BACKUP_DIR}/metadata/versions.txt"
    echo "Hostname: $(hostname)" >> "${BACKUP_DIR}/metadata/versions.txt"
    echo "Kernel: $(uname -r)" >> "${BACKUP_DIR}/metadata/versions.txt"
    echo "" >> "${BACKUP_DIR}/metadata/versions.txt"
    echo "=== SERVICES ===" >> "${BACKUP_DIR}/metadata/versions.txt"
    docker --version >> "${BACKUP_DIR}/metadata/versions.txt" 2>/dev/null || true
    kubectl version --short >> "${BACKUP_DIR}/metadata/versions.txt" 2>/dev/null || true
    echo "Jenkins: $(curl -s http://localhost:8080 | grep -o 'Jenkins [0-9.]*' | head -1)" >> "${BACKUP_DIR}/metadata/versions.txt" 2>/dev/null || true
    echo "SonarQube: Port 9000" >> "${BACKUP_DIR}/metadata/versions.txt"
    echo "Nexus: Port 8081" >> "${BACKUP_DIR}/metadata/versions.txt"
    trivy --version >> "${BACKUP_DIR}/metadata/versions.txt" 2>/dev/null || true
    echo "" >> "${BACKUP_DIR}/metadata/versions.txt"
    echo "=== DOCKER ===" >> "${BACKUP_DIR}/metadata/versions.txt"
    docker ps -a >> "${BACKUP_DIR}/metadata/versions.txt" 2>/dev/null || true
    echo "" >> "${BACKUP_DIR}/metadata/versions.txt"
    echo "=== KUBERNETES ===" >> "${BACKUP_DIR}/metadata/versions.txt"
    kubectl get nodes >> "${BACKUP_DIR}/metadata/versions.txt" 2>/dev/null || true
    kubectl get pods -A >> "${BACKUP_DIR}/metadata/versions.txt" 2>/dev/null || true
    
    log_success "Métadonnées sauvegardées"
    
    # ============ 8. ARCHIVAGE FINAL ============
    log_info "[8/8] Archivage complet..."
    
    cd "${BACKUP_DIR}/.."
    tar --exclude='*.tar.gz' -czf "devops_backup_complet_${TIMESTAMP}.tar.gz" devops_complet/ 2>/dev/null
    
    BACKUP_FILE="$(pwd)/devops_backup_complet_${TIMESTAMP}.tar.gz"
    BACKUP_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
    
    log_success "Archive créée: ${BACKUP_FILE}"
    log_success "Taille: ${BACKUP_SIZE}"
    
    log_info "================================================"
    log_success "SAUVEGARDE COMPLÈTE TERMINÉE"
    log_info "================================================"
    echo ""
    echo -e "${GREEN}Localisation de l'archive:${NC}"
    echo "  ${BACKUP_FILE}"
    echo ""
    echo -e "${YELLOW}Étapes suivantes:${NC}"
    echo "  1. Transférer l'archive vers le nouvel environnement:"
    echo "     scp ${BACKUP_FILE} user@NEW_SERVER:/tmp/"
    echo ""
    echo "  2. Sur le nouvel environnement, restaurer avec:"
    echo "     sudo ./clone_infra.sh"
    echo "     → Choisir option 2 (Restaurer)"
    echo ""
}

################################################################################
# SECTION 2: RESTAURATION COMPLÈTE
################################################################################

restore_complete() {
    local BACKUP_FILE=$1
    
    log_info "================================================"
    log_info "DÉBUT RESTAURATION INFRASTRUCTURE"
    log_info "================================================"
    
    if [ ! -f "${BACKUP_FILE}" ]; then
        log_error "Fichier ${BACKUP_FILE} introuvable"
        exit 1
    fi
    
    log_info "Extraction archive..."
    RESTORE_DIR="/tmp/devops_restore_${TIMESTAMP}"
    mkdir -p "${RESTORE_DIR}"
    tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}" 2>/dev/null
    
    # ============ 1. CONFIGURATIONS RÉSEAU ============
    log_info "[1/7] Restauration RÉSEAU..."
    if [ -d "${RESTORE_DIR}/devops_complet/network/netplan" ]; then
        cp -r "${RESTORE_DIR}/devops_complet/network/netplan"/* /etc/netplan/ 2>/dev/null || true
        netplan apply
    fi
    log_success "Réseau restauré"
    
    # ============ 2. DOCKER ============
    log_info "[2/7] Restauration DOCKER..."
    if [ -d "${RESTORE_DIR}/devops_complet/docker/config" ]; then
        cp -r "${RESTORE_DIR}/devops_complet/docker/config"/* /etc/docker/ 2>/dev/null || true
    fi
    
    systemctl restart docker
    
    # Import des images
    log_info "    → Import images Docker..."
    for img in "${RESTORE_DIR}"/devops_complet/docker/*.tar; do
        if [ -f "${img}" ]; then
            log_info "      Import: $(basename ${img})"
            docker load -i "${img}" 2>/dev/null || true
        fi
    done
    
    log_success "Docker restauré"
    
    # ============ 3. KUBERNETES ============
    log_info "[3/7] Restauration KUBERNETES..."
    if [ -d "${RESTORE_DIR}/devops_complet/kubernetes/etc-kubernetes" ]; then
        cp -r "${RESTORE_DIR}/devops_complet/kubernetes/etc-kubernetes"/* /etc/kubernetes/ 2>/dev/null || true
    fi
    
    mkdir -p ~/.kube
    if [ -f "${RESTORE_DIR}/devops_complet/kubernetes/kubeconfig/config" ]; then
        cp "${RESTORE_DIR}/devops_complet/kubernetes/kubeconfig/config" ~/.kube/ 2>/dev/null || true
        chmod 600 ~/.kube/config
    fi
    
    # Restaurer etcd si présent
    if [ -d "${RESTORE_DIR}/devops_complet/kubernetes/etcd" ]; then
        log_info "    → Restauration etcd..."
        cp -r "${RESTORE_DIR}/devops_complet/kubernetes/etcd"/* /var/lib/etcd/ 2>/dev/null || true
    fi
    
    systemctl restart kubelet
    sleep 5
    
    # Appliquer les manifests
    log_info "    → Application des manifests Kubernetes..."
    if [ -f "${RESTORE_DIR}/devops_complet/kubernetes/manifests/all_resources.yaml" ]; then
        kubectl apply -f "${RESTORE_DIR}/devops_complet/kubernetes/manifests/all_resources.yaml" 2>/dev/null || true
    fi
    
    log_success "Kubernetes restauré"
    
    # ============ 4. JENKINS ============
    log_info "[4/7] Restauration JENKINS (jobs, pipelines, credentials)..."
    
    systemctl stop jenkins 2>/dev/null || true
    sleep 3
    
    if [ -d "${RESTORE_DIR}/devops_complet/jenkins/jobs" ]; then
        cp -r "${RESTORE_DIR}/devops_complet/jenkins/jobs"/* /var/lib/jenkins/jobs/ 2>/dev/null || true
    fi
    if [ -d "${RESTORE_DIR}/devops_complet/jenkins/secrets" ]; then
        cp -r "${RESTORE_DIR}/devops_complet/jenkins/secrets"/* /var/lib/jenkins/secrets/ 2>/dev/null || true
    fi
    if [ -d "${RESTORE_DIR}/devops_complet/jenkins/plugins" ]; then
        cp -r "${RESTORE_DIR}/devops_complet/jenkins/plugins"/* /var/lib/jenkins/plugins/ 2>/dev/null || true
    fi
    if [ -d "${RESTORE_DIR}/devops_complet/jenkins/users" ]; then
        cp -r "${RESTORE_DIR}/devops_complet/jenkins/users"/* /var/lib/jenkins/users/ 2>/dev/null || true
    fi
    if [ -f "${RESTORE_DIR}/devops_complet/jenkins/config.xml" ]; then
        cp "${RESTORE_DIR}/devops_complet/jenkins/config.xml" /var/lib/jenkins/ 2>/dev/null || true
    fi
    if [ -f "${RESTORE_DIR}/devops_complet/jenkins/credentials.xml" ]; then
        cp "${RESTORE_DIR}/devops_complet/jenkins/credentials.xml" /var/lib/jenkins/ 2>/dev/null || true
    fi
    
    chown -R jenkins:jenkins /var/lib/jenkins/
    systemctl start jenkins 2>/dev/null || true
    sleep 5
    
    log_success "Jenkins restauré"
    
    # ============ 5. NEXUS ============
    log_info "[5/7] Restauration NEXUS (repositories, artifacts)..."
    
    docker stop nexus 2>/dev/null || true
    sleep 2
    
    if [ -d "${RESTORE_DIR}/devops_complet/nexus/nexus-data" ]; then
        docker cp "${RESTORE_DIR}/devops_complet/nexus/nexus-data" nexus:/nexus-data 2>/dev/null || true
    fi
    
    docker start nexus 2>/dev/null || true
    sleep 5
    
    log_success "Nexus restauré"
    
    # ============ 6. SONARQUBE ============
    log_info "[6/7] Restauration SONARQUBE (projets, analyses)..."
    
    docker stop sonar 2>/dev/null || true
    sleep 2
    
    if [ -d "${RESTORE_DIR}/devops_complet/sonarqube/data" ]; then
        docker cp "${RESTORE_DIR}/devops_complet/sonarqube/data" sonar:/opt/sonarqube/ 2>/dev/null || true
    fi
    if [ -d "${RESTORE_DIR}/devops_complet/sonarqube/extensions" ]; then
        docker cp "${RESTORE_DIR}/devops_complet/sonarqube/extensions" sonar:/opt/sonarqube/ 2>/dev/null || true
    fi
    if [ -d "${RESTORE_DIR}/devops_complet/sonarqube/conf" ]; then
        docker cp "${RESTORE_DIR}/devops_complet/sonarqube/conf" sonar:/opt/sonarqube/ 2>/dev/null || true
    fi
    
    docker start sonar 2>/dev/null || true
    sleep 5
    
    log_success "SonarQube restauré"
    
    # ============ 7. NETTOYAGE ============
    log_info "[7/7] Nettoyage..."
    rm -rf "${RESTORE_DIR}"
    
    log_info "================================================"
    log_success "RESTAURATION COMPLÈTE TERMINÉE"
    log_info "================================================"
    echo ""
    echo -e "${GREEN}✓ Tous les services ont été restaurés${NC}"
    echo ""
    echo -e "${YELLOW}Vérifications à faire:${NC}"
    echo "  1. Jenkins: http://localhost:8080"
    echo "  2. SonarQube: http://localhost:9000"
    echo "  3. Nexus: http://localhost:8081"
    echo "  4. Kubernetes: kubectl get nodes / kubectl get pods -A"
    echo ""
}

################################################################################
# SECTION 3: MIGRATION IPs
################################################################################

migrate_ips() {
    local OLD_IP=$1
    local NEW_IP=$2
    
    log_info "Mise à jour IP: ${OLD_IP} → ${NEW_IP}"
    
    # Netplan
    sed -i "s/${OLD_IP}/${NEW_IP}/g" /etc/netplan/*.yaml 2>/dev/null || true
    netplan apply
    
    # Kubernetes
    sed -i "s/${OLD_IP}/${NEW_IP}/g" /etc/kubernetes/manifests/*.yaml 2>/dev/null || true
    sed -i "s/${OLD_IP}/${NEW_IP}/g" ~/.kube/config 2>/dev/null || true
    
    # Jenkins
    sed -i "s/${OLD_IP}/${NEW_IP}/g" /var/lib/jenkins/config.xml 2>/dev/null || true
    
    systemctl restart docker kubelet jenkins 2>/dev/null || true
    
    log_success "IPs mises à jour"
}

################################################################################
# SECTION 4: MENU PRINCIPAL
################################################################################

show_menu() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   OUTIL COMPLET DE CLONAGE INFRASTRUCTURE DEVOPS          ║"
    echo "║   (Jenkins + Nexus + SonarQube + Docker + Kubernetes)    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo "  1) Sauvegarder TOUT (Jenkins+Nexus+SonarQube+Docker+K8s)"
    echo "  2) Restaurer une sauvegarde complète"
    echo "  3) Migrer vers nouvel environnement (changement IPs)"
    echo "  4) Lister les sauvegardes disponibles"
    echo "  5) Afficher le log"
    echo "  6) Quitter"
    echo ""
}

list_backups() {
    echo -e "${BLUE}Sauvegardes disponibles:${NC}"
    ls -lh /backup/devops_backup_complet_*.tar.gz 2>/dev/null || ls -lh /tmp/devops_backup_complet_*.tar.gz 2>/dev/null || echo "Aucune sauvegarde trouvée"
}

show_log() {
    if [ -f "${LOG_FILE}" ]; then
        less "${LOG_FILE}"
    else
        echo "Aucun log disponible"
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    check_root
    
    # Créer log directory
    mkdir -p "${BACKUP_DIR}"
    
    while true; do
        show_menu
        read -p "Choisir une option [1-6]: " choice
        
        case $choice in
            1)
                backup_complete
                read -p "Appuyer sur Entrée..."
                ;;
            2)
                list_backups
                read -p "Chemin complet du fichier de sauvegarde: " backup_file
                restore_complete "${backup_file}"
                read -p "Appuyer sur Entrée..."
                ;;
            3)
                read -p "Ancienne IP: " old_ip
                read -p "Nouvelle IP: " new_ip
                migrate_ips "${old_ip}" "${new_ip}"
                read -p "Appuyer sur Entrée..."
                ;;
            4)
                list_backups
                read -p "Appuyer sur Entrée..."
                ;;
            5)
                show_log
                ;;
            6)
                log_info "Au revoir !"
                exit 0
                ;;
            *)
                echo -e "${RED}Option invalide${NC}"
                read -p "Appuyer sur Entrée..."
                ;;
        esac
    done
}

# Lancer
main
