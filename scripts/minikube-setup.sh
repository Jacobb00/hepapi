#!/bin/bash
#=============================================================================
# Minikube Kurulum ve Uygulama Deploy Scripti
# Bu script Minikube cluster'i kurar ve uygulamayi deploy eder
#=============================================================================

set -e  # Hata olursa dur

# Renkli output icin
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Task Manager - Minikube Setup Script   ${NC}"
echo -e "${GREEN}========================================${NC}"

#-----------------------------------------------------------------------------
# 1. Gerekli araclarin kontrolu
#-----------------------------------------------------------------------------
echo -e "\n${YELLOW}[1/6] Gerekli araclar kontrol ediliyor...${NC}"

# Docker kontrolu
if ! command -v docker &> /dev/null; then
    echo -e "${RED}HATA: Docker yuklu degil!${NC}"
    echo "Docker'i yuklemek icin: https://docs.docker.com/get-docker/"
    exit 1
fi
echo "  ✓ Docker bulundu: $(docker --version)"

# kubectl kontrolu
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}HATA: kubectl yuklu degil!${NC}"
    echo "kubectl'i yuklemek icin: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi
echo "  ✓ kubectl bulundu: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# Minikube kontrolu
if ! command -v minikube &> /dev/null; then
    echo -e "${RED}HATA: Minikube yuklu degil!${NC}"
    echo "Minikube'u yuklemek icin: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi
echo "  ✓ Minikube bulundu: $(minikube version --short)"

#-----------------------------------------------------------------------------
# 2. Minikube cluster baslatma
#-----------------------------------------------------------------------------
echo -e "\n${YELLOW}[2/6] Minikube cluster baslatiliyor...${NC}"

# Eger zaten calisiyor mu kontrol et
if minikube status | grep -q "Running"; then
    echo "  ✓ Minikube zaten calisiyor"
else
    minikube start --driver=docker --cpus=2 --memory=2048
    echo "  ✓ Minikube baslatildi"
fi

#-----------------------------------------------------------------------------
# 3. Docker image'i Minikube icinde build etme
#-----------------------------------------------------------------------------
echo -e "\n${YELLOW}[3/6] Docker image build ediliyor (Minikube icinde)...${NC}"

# Minikube'un Docker daemon'ina baglan
# Bu sayede image'i push etmeye gerek kalmaz
eval $(minikube docker-env)

# Image'i build et
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

docker build -t task-manager:latest "$PROJECT_DIR"
echo "  ✓ Docker image build edildi: task-manager:latest"

#-----------------------------------------------------------------------------
# 4. Kubernetes manifest'lerini uygula
#-----------------------------------------------------------------------------
echo -e "\n${YELLOW}[4/6] Kubernetes manifest'leri uygulanıyor...${NC}"

# Sirayla uygula (namespace once olmali)
kubectl apply -f "$PROJECT_DIR/k8s/namespace.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/mongodb-secret.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/mongodb-pvc.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/mongodb-deployment.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/mongodb-service.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/app-configmap.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/app-deployment.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/app-service.yaml"

echo "İşlem tamam devamke"

#-----------------------------------------------------------------------------
# 5. Pod'larin hazir olmasini bekle
#-----------------------------------------------------------------------------
echo -e "\n${YELLOW}[5/6] Pod'lar baslatiliyor, lutfen bekleyin...${NC}"

kubectl wait --for=condition=ready pod -l app=mongodb -n task-manager --timeout=120s
echo "  ✓ MongoDB hazir"

kubectl wait --for=condition=ready pod -l app=task-manager -n task-manager --timeout=120s
echo "  ✓ Flask App hazir"

#-----------------------------------------------------------------------------
# 6. Erisim bilgilerini goster
#-----------------------------------------------------------------------------
echo -e "\n${YELLOW}[6/6] Deployment tamamlandi!${NC}"

# Servis URL'sini al
SERVICE_URL=$(minikube service task-manager-service -n task-manager --url 2>/dev/null || echo "")

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN} DEPLOYMENT BASARILI!                   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Uygulamaya erismek icin:"
if [ -n "$SERVICE_URL" ]; then
    echo -e "  URL: ${GREEN}${SERVICE_URL}${NC}"
else
    echo -e "  Komutu calistir: ${GREEN}minikube service task-manager-service -n task-manager${NC}"
fi
echo ""
echo "Faydali komutlar:"
echo "  Pod'lari gor:     kubectl get pods -n task-manager"
echo "  Loglari gor:      kubectl logs -f deployment/task-manager-app -n task-manager"
echo "  Cluster'i durdur: minikube stop"
echo "  Cluster'i sil:    minikube delete"
