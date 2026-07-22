# Informe de Orquestación de Smart Contract en Kubernetes

**Autor:** Andrés Alejandro Silva Aguilar
**Institución:** Universidad Técnica Particular de Loja (UTPL)
**Fecha:** Julio 2026

## 1. Descripción del Smart Contract
* **Nombre:** `Counter.sol`
* **Objetivo:** Contrato inteligente base para demostrar el despliegue en un entorno orquestado. Provee un mecanismo descentralizado de registro y consulta de un contador.
* **Funciones Principales:**
  - `increment()`: Aumenta el contador en 1 unidad y emite el evento `CountIncremented`.
  - `getCount()`: Función `view` que retorna el estado actual del contador.

## 2. Arquitectura de Despliegue
El sistema se orquesta bajo un **Deployment** de Kubernetes, que mantiene un **ReplicaSet** para garantizar la disponibilidad de los Pods. El tráfico interno se enruta mediante un **Service (ClusterIP)**.

```text
+-----------------------------------------------------------------------+
|                         KUBERNETES CLUSTER                            |
|   +---------------------------------------------------------------+   |
|   |                  Service: smart-contract-service              |   |
|   |                        (Port 8545)                            |   |
|   +-------------------------------+-------------------------------+   |
|                                   |                                   |
|   +-------------------------------+-------------------------------+   |
|   |               Deployment: smart-contract-deployment           |   |
|   |   +-------------------------------------------------------+   |   |
|   |   |                  ReplicaSet Active                    |   |   |
|   |   |  +---------------+  +---------------+  +-----------+  |   |   |
|   |   |  | Pod 1 (Ganache)|  | Pod 2 (Ganache)|  | Pod 3...  |  |   |   |
|   |   |  +---------------+  +---------------+  +-----------+  |   |   |
|   |   +-------------------------------------------------------+   |   |
|   +---------------------------------------------------------------+   |
+-----------------------------------------------------------------------+
```

## 3. Pasos Seguidos y Evidencias (Capturas de Terminal)

### A. Despliegue Inicial (3 Réplicas)
Se aplica el manifiesto original `kubectl apply -f k8s/deployment.yaml`.
**Evidencia del estado de los Pods y ReplicaSets:**
```bash
$ kubectl get pods
NAME                                        READY   STATUS              RESTARTS   AGE
smart-contract-deployment-f95b84bc8-h82lx   0/1     ContainerCreating   0          15s
smart-contract-deployment-f95b84bc8-kpft9   0/1     ContainerCreating   0          15s
smart-contract-deployment-f95b84bc8-qdmpx   0/1     ContainerCreating   0          15s

$ kubectl get rs
NAME                                  DESIRED   CURRENT   READY   AGE
smart-contract-deployment-f95b84bc8   3         3         0       15s
```

### B. Cambio en Caliente 1: Escalado a 5 Réplicas
Comando ejecutado: `kubectl scale deployment/smart-contract-deployment --replicas=5`
**Evidencia del escalado exitoso:**
```bash
$ kubectl get pods
NAME                                        READY   STATUS              RESTARTS   AGE
smart-contract-deployment-f95b84bc8-h82lx   1/1     Running             0          23s
smart-contract-deployment-f95b84bc8-kkgcc   0/1     ContainerCreating   0          8s
smart-contract-deployment-f95b84bc8-kpft9   1/1     Running             0          23s
smart-contract-deployment-f95b84bc8-qdmpx   0/1     ContainerCreating   0          23s
smart-contract-deployment-f95b84bc8-sxdx5   0/1     ContainerCreating   0          8s

$ kubectl get rs
NAME                                  DESIRED   CURRENT   READY   AGE
smart-contract-deployment-f95b84bc8   5         5         2       24s
```

### C. Cambio en Caliente 2: Rolling Update
Comando ejecutado: `kubectl set image deployment/smart-contract-deployment contract-container=trufflesuite/ganache-cli:v6.12.2`
Comando de monitorización: `kubectl rollout status deployment/smart-contract-deployment`
**Evidencia de resiliencia y actualización sin interrupciones:**
```bash
$ kubectl rollout status...
Waiting for deployment spec update to be observed...
Waiting for deployment "smart-contract-deployment" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "smart-contract-deployment" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "smart-contract-deployment" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "smart-contract-deployment" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "smart-contract-deployment" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "smart-contract-deployment" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "smart-contract-deployment" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "smart-contract-deployment" rollout to finish: 4 of 5 updated replicas are available...
deployment "smart-contract-deployment" successfully rolled out

$ kubectl get pods
NAME                                         READY   STATUS        RESTARTS   AGE
smart-contract-deployment-7ffc578b44-8n99r   1/1     Running       0          21s
smart-contract-deployment-7ffc578b44-8vdh7   1/1     Running       0          21s
smart-contract-deployment-7ffc578b44-dddfd   1/1     Running       0          21s
smart-contract-deployment-7ffc578b44-hr5l2   1/1     Running       0          18s
smart-contract-deployment-7ffc578b44-vrczr   1/1     Running       0          17s
smart-contract-deployment-f95b84bc8-h82lx    1/1     Terminating   0          46s
smart-contract-deployment-f95b84bc8-kkgcc    1/1     Terminating   0          31s
smart-contract-deployment-f95b84bc8-kpft9    1/1     Terminating   0          46s
smart-contract-deployment-f95b84bc8-qdmpx    1/1     Terminating   0          46s
smart-contract-deployment-f95b84bc8-sxdx5    1/1     Terminating   0          31s

$ kubectl get rs
NAME                                   DESIRED   CURRENT   READY   AGE
smart-contract-deployment-7ffc578b44   5         5         5       23s
smart-contract-deployment-f95b84bc8    0         0         0       47s
```
