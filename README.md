# 📋 Task Manager — Flask + MongoDB

A simple CRUD Task Manager application built with **Python Flask** and **MongoDB**, fully containerized and orchestrated with **Kubernetes**.

## 🏗️ Architecture

```
                    ┌─────────────────────────────────────┐
                    │         GitHub Actions CI/CD        │
                    │  Lint → Test → Build → Push → Deploy│
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
                    │        Kubernetes (Minikube)         │
                    │                                      │
                    │  ┌────────────────────────────────┐  │
                    │  │    Flask App (2 replicas)       │  │
                    │  │    - Gunicorn WSGI Server       │  │
                    │  │    - Rolling Update Strategy    │  │
                    │  │    - Health Checks              │  │
                    │  └───────────────┬────────────────┘  │
                    │                  │                    │
                    │  ┌───────────────▼────────────────┐  │
                    │  │    MongoDB (1 replica)          │  │
                    │  │    - Persistent Volume          │  │
                    │  │    - Secret-based Auth          │  │
                    │  └────────────────────────────────┘  │
                    └──────────────────────────────────────┘
```

## 📁 Project Structure

```
flask-mongodb/
├── .github/workflows/
│   └── ci.yml                  # CI/CD Pipeline (GitHub Actions)
├── helm/task-manager/          # Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── k8s/                        # Kubernetes Manifests
│   ├── namespace.yaml
│   ├── app-configmap.yaml
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   ├── mongodb-pvc.yaml
│   ├── mongodb-secret.yaml
│   ├── mongodb-deployment.yaml
│   └── mongodb-service.yaml
├── scripts/
│   ├── minikube-setup.sh       # Automated Minikube setup
│   └── deploy.sh               # Quick redeploy script
├── templates/
│   └── home.html               # Jinja2 HTML template
├── tests/
│   └── test_app.py             # Unit tests
├── .dockerignore
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── classes.py                  # Flask-WTF form classes
├── requirements.txt
├── run.py                      # Main Flask application
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) (for Kubernetes deployment)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) (optional, for Helm deployment)

---

### Option 1: Docker Compose -- no auto no k8s

Run the entire stack with a single command:

```bash
# Build and start the application
docker-compose up -d

# Open in browser
# http://localhost:5000

# Stop the application
docker-compose down

# Stop and remove volumes (delete all data)
docker-compose down -v
```

---

### Option 2: Kubernetes with Minikube

#### Automated Setup (Recommended)

```bash
# Make the script executable and drink your coffe
chmod +x scripts/minikube-setup.sh

# Run the setup script
./scripts/minikube-setup.sh
```

The script will:
1. ✅ Check prerequisites (Docker, kubectl, Minikube)
2. ✅ Start Minikube cluster
3. ✅ Build Docker image inside Minikube
4. ✅ Apply all Kubernetes manifests
5. ✅ Wait for pods to be ready
6. ✅ Display the application URL

#### Manual Setup

```bash
# 1. Start Minikube
minikube start --driver=docker

# 2. Use Minikube's Docker daemon
eval $(minikube docker-env)

# 3. Build the Docker image
docker build -t task-manager:latest .

# 4. Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mongodb-secret.yaml
kubectl apply -f k8s/mongodb-pvc.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml

# 5. Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=mongodb -n task-manager --timeout=120s
kubectl wait --for=condition=ready pod -l app=task-manager -n task-manager --timeout=120s

# 6. Access the application
minikube service task-manager-service -n task-manager
```

---

### Option 3: Helm Chart

```bash
# Start Minikube and build the image (steps 1-3 from above)
minikube start --driver=docker
eval $(minikube docker-env)
docker build -t task-manager:latest .

# Install with Helm
helm install task-manager ./helm/task-manager

# Customize values
helm install task-manager ./helm/task-manager --set app.replicas=3

# Upgrade after changes
helm upgrade task-manager ./helm/task-manager

# Uninstall
helm uninstall task-manager
```

---

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline runs on every push/PR to `main`:

| Stage | Tool | Description |
|-------|------|-------------|
| **Lint** | flake8 | Python code quality check |
| **Test** | pytest | Unit tests |
| **Build & Push** | Docker | Build image and push to Docker Hub |
| **Deploy** | kubectl | Deploy to Kubernetes (manual approval) |

### Setup CI/CD

Add these secrets to your GitHub repository (`Settings > Secrets > Actions`):

- `DOCKER_HUB_USERNAME` — Your Docker Hub username
- `DOCKER_HUB_TOKEN` — Your Docker Hub access token

---

## 🛠️ Useful Commands

```bash
# View pods
kubectl get pods -n task-manager

# View services
kubectl get svc -n task-manager

# View logs
kubectl logs -f deployment/task-manager-app -n task-manager

# Scale the application
kubectl scale deployment/task-manager-app --replicas=3 -n task-manager

# Redeploy after code changes
./scripts/deploy.sh

# Delete everything
kubectl delete namespace task-manager
minikube stop
```



## 📝 Design Decisions

- **Non-root Docker user**: Security best practice — container runs as `appuser`, not root
- **Gunicorn**: Production-grade WSGI server instead of Flask's built-in dev server
- **2 replicas**: High Availability — if one pod crashes, the other serves traffic
- **Rolling Update**: Zero-downtime deployments with `maxSurge=1, maxUnavailable=0`
- **PersistentVolumeClaim**: MongoDB data survives pod restarts
- **Kubernetes Secrets**: Sensitive data (DB credentials) stored securely
- **ConfigMap**: Application config separated from code (12-factor app)
- **Health Probes**: Kubernetes automatically restarts unhealthy pods
- **Resource Limits**: Fair resource sharing in the cluster
- **Environment Variables**: MongoDB URI configurable per environment (dev/staging/prod)