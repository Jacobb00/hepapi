# Madde 3 — Minikube Kurulum ve Test minikube outputun açıklmaası 

Ortam: Windows, Docker driver, `flask-mongodb` klasörü.

---

## 1. Image build

```powershell
cd C:\dev\hepapi\flask-mongodb
minikube docker-env --shell powershell | Invoke-Expression
docker build -t task-manager:latest .
```

**Çıktı:**
```
[+] Building 6.0s (11/11) FINISHED
 => naming to docker.io/library/task-manager:latest
```

---

## 2. Manifest deploy

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mongodb-secret.yaml
kubectl apply -f k8s/mongodb-pvc.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
```

**Çıktı:**
```
namespace/task-manager unchanged
secret/mongodb-secret unchanged
persistentvolumeclaim/mongodb-pvc unchanged
deployment.apps/mongodb unchanged
service/mongodb-service unchanged
configmap/app-config unchanged
deployment.apps/task-manager-app unchanged
service/task-manager-service unchanged
```

---

## 3. Pod hazırlığı

```powershell
kubectl wait --for=condition=ready pod -l app=mongodb -n task-manager --timeout=180s
kubectl wait --for=condition=ready pod -l app=task-manager -n task-manager --timeout=180s
kubectl get pods -n task-manager
```

**Çıktı:**
```
pod/mongodb-5768bb9f97-5shrr condition met
pod/task-manager-app-b68648979-42b47 condition met
pod/task-manager-app-b68648979-v65kd condition met

NAME                               READY   STATUS    RESTARTS   AGE
mongodb-5768bb9f97-5shrr           1/1     Running   0          6m17s
task-manager-app-b68648979-42b47   1/1     Running   0          6m16s
task-manager-app-b68648979-v65kd   1/1     Running   0          6m16s
```

---

## 4. Uygulama erişimi

```powershell
minikube service task-manager-service -n task-manager --url
```

**Çıktı:**
```
http://127.0.0.1:50111
❗  Because you are using a Docker driver on windows, the terminal needs to be open to run it.
```



Tarayıcıda açmak için:
```powershell
minikube service task-manager-service -n task-manager
```

---

## 5. Kontrol testleri

```powershell
kubectl get pods -n task-manager
kubectl get svc -n task-manager
kubectl get deployments -n task-manager
```

**Pod’lar:**
```
NAME                               READY   STATUS    RESTARTS   AGE
mongodb-5768bb9f97-5shrr           1/1     Running   0          9m35s
task-manager-app-b68648979-42b47   1/1     Running   0          9m34s
task-manager-app-b68648979-v65kd   1/1     Running   0          9m34s
```

**Servisler:**
```
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
mongodb-service        ClusterIP   10.102.246.222   <none>        27017/TCP        9m53s
task-manager-service   NodePort    10.103.168.209   <none>        5000:30080/TCP   9m52s
```

**Deployment’lar:**
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
mongodb            1/1     1            1           9m53s
task-manager-app   2/2     2            2           9m52s
```



