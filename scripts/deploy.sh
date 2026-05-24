#!/bin/bash
#=============================================================================
# Hizli Deploy Scripti
# Mevcut Minikube cluster'a uygulamayi yeniden deploy eder
# Kullanim: ./scripts/deploy.sh chmod iznini unutma!
#=============================================================================
##flask kodunda bi değişiklik olduğu zaman sadece değişen kodu derler ve günceller
set -e ## hata engelleme kodumuz

GREEN='\033[0;32m' #renk şöleni
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Minikube calisiyor mu kontrol et çalışmıyorsa gırmızı hata kodu 
if ! minikube status | grep -q "Running"; then
    echo -e "${RED}HATA: Minikube calismıyor! Once 'minikube start' calistirin.${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}[1/3] Docker image yeniden build ediliyor...${NC}"
eval $(minikube docker-env)
docker build -t task-manager:latest "$PROJECT_DIR"

echo -e "${YELLOW}[2/3] Deployment yeniden baslatiliyor...${NC}"
kubectl rollout restart deployment/task-manager-app -n task-manager

echo -e "${YELLOW}[3/3] Rollout bekleniyor...${NC}"
kubectl rollout status deployment/task-manager-app -n task-manager --timeout=60s

echo -e "\n${GREEN}✓ Deploy tamamlandi!${NC}"
echo -e "Erisim icin: ${GREEN}minikube service task-manager-service -n task-manager${NC}"
