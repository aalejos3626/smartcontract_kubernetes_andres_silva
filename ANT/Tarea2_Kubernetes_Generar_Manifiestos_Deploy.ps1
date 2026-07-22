param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$Namespace = "tarea2-kubernetes",
    [string]$DeploymentName = "smartcontract-k8s",
    [string]$DockerHubUser = "alejos3626",
    [string]$ImageName = "smartcontract_docker_andres_alejandro_silva_aguilar",
    [string]$TagV1 = "1.0",
    [string]$TagV2 = "2.0",
    [string]$GitEmail = "andres3626@gmail.com",
    [switch]$SkipDockerPush,
    [switch]$SkipKubernetesApply
)

# Tarea2_Kubernetes_Generar_Manifiestos_Deploy.ps1
# Autor: Andres Alejandro Silva Aguilar
# Objetivo: preparar y ejecutar la Tarea 2 de Kubernetes para el proyecto de smart contract en Docker.
# Este script crea manifiestos YAML, evidencia en TXT y permite desplegar el contenedor en Kubernetes.

$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$Author = "Andres Alejandro Silva Aguilar"
$ImageV1 = "{0}/{1}:{2}" -f $DockerHubUser, $ImageName, $TagV1
$ImageV2 = "{0}/{1}:{2}" -f $DockerHubUser, $ImageName, $TagV2

function Title($text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Utf8NoBom($Path, $Content) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Save-CommandOutput($CommandText, $OutputFile) {
    Write-Host "Ejecutando: $CommandText" -ForegroundColor Yellow
    $result = cmd /c $CommandText 2>&1
    $content = "Comando: $CommandText`r`nFecha: $(Get-Date)`r`n`r`n$result`r`n"
    Write-Utf8NoBom $OutputFile $content
    Write-Host $result
}

Title "Tarea 2 - Kubernetes para smart contract en Docker"
Write-Host "Autor: $Author" -ForegroundColor Green
Write-Host "Proyecto: $ProjectPath" -ForegroundColor Yellow
Write-Host "Imagen v1: $ImageV1" -ForegroundColor Yellow
Write-Host "Imagen v2: $ImageV2" -ForegroundColor Yellow
Write-Host "Namespace: $Namespace" -ForegroundColor Yellow

if (-not (Test-Path $ProjectPath)) {
    Write-Host "No existe la ruta del proyecto: $ProjectPath" -ForegroundColor Red
    exit 1
}

Set-Location $ProjectPath

Title "1. Validando estructura del proyecto"
$requiredFiles = @("Dockerfile", "package.json", "contracts\CertificacionCredenciales.sol")
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "Falta archivo requerido: $file" -ForegroundColor Red
        Write-Host "Ejecuta este script desde la carpeta principal del proyecto." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "Estructura base verificada." -ForegroundColor Green

Title "2. Creando carpetas para Kubernetes y evidencias"
$K8sPath = Join-Path $ProjectPath "k8s"
$DocsPath = Join-Path $ProjectPath "docs"
$EvidencePath = Join-Path $DocsPath "evidencias-tarea2"
New-Item -ItemType Directory -Force -Path $K8sPath | Out-Null
New-Item -ItemType Directory -Force -Path $EvidencePath | Out-Null
Write-Host "Carpetas creadas: k8s y docs/evidencias-tarea2" -ForegroundColor Green

Title "3. Generando manifiestos YAML"

$namespaceYaml = @"
apiVersion: v1
kind: Namespace
metadata:
  name: $Namespace
"@

$deploymentV1Yaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DeploymentName
  namespace: $Namespace
  labels:
    app: $DeploymentName
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: $DeploymentName
  template:
    metadata:
      labels:
        app: $DeploymentName
        version: "$TagV1"
    spec:
      containers:
        - name: smartcontract-container
          image: $ImageV1
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Iniciando contenedor del smart contract - version $TagV1"
              npm test
              node -e "require('http').createServer((req,res)=>res.end('smartcontract k8s version $TagV1')).listen(3000,'0.0.0.0')"
"@

$deploymentV2Yaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DeploymentName
  namespace: $Namespace
  labels:
    app: $DeploymentName
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: $DeploymentName
  template:
    metadata:
      labels:
        app: $DeploymentName
        version: "$TagV2"
    spec:
      containers:
        - name: smartcontract-container
          image: $ImageV2
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Iniciando contenedor del smart contract - version $TagV2"
              npm test
              node -e "require('http').createServer((req,res)=>res.end('smartcontract k8s version $TagV2')).listen(3000,'0.0.0.0')"
"@

$serviceYaml = @"
apiVersion: v1
kind: Service
metadata:
  name: $DeploymentName-service
  namespace: $Namespace
spec:
  type: ClusterIP
  selector:
    app: $DeploymentName
  ports:
    - name: http
      port: 80
      targetPort: 3000
"@

Write-Utf8NoBom (Join-Path $K8sPath "namespace.yaml") $namespaceYaml
Write-Utf8NoBom (Join-Path $K8sPath "deployment-v1.yaml") $deploymentV1Yaml
Write-Utf8NoBom (Join-Path $K8sPath "deployment-v2.yaml") $deploymentV2Yaml
Write-Utf8NoBom (Join-Path $K8sPath "service.yaml") $serviceYaml

Write-Host "Archivos generados:" -ForegroundColor Green
Write-Host "- k8s/namespace.yaml"
Write-Host "- k8s/deployment-v1.yaml"
Write-Host "- k8s/deployment-v2.yaml"
Write-Host "- k8s/service.yaml"

Title "4. Generando informe base en Markdown"
$reportMd = @"
# Informe Tarea 2 - Orquestacion de smart contract con Kubernetes

Autor: Andres Alejandro Silva Aguilar

## 1. Descripcion del smart contract

El smart contract utilizado se llama `CertificacionCredenciales`. Su objetivo es simular un sistema basico de certificacion digital basado en blockchain. El contrato permite emitir, validar, consultar y revocar certificados digitales mediante hashes, evitando almacenar datos personales o documentos completos.

Funciones principales:

- Emitir certificados digitales.
- Validar certificados mediante hashes.
- Consultar informacion basica del certificado.
- Revocar certificados.
- Controlar emisores autorizados.

## 2. Imagen Docker utilizada

Imagen version 1:

```text
$ImageV1
```

Imagen version 2 para rolling update:

```text
$ImageV2
```

## 3. Arquitectura de despliegue

```text
Docker Hub Image
      |
      v
Kubernetes Deployment: $DeploymentName
      |
      v
ReplicaSet
      |
      v
Pods: 3 replicas iniciales -> 5 replicas despues del escalamiento
      |
      v
Service: $DeploymentName-service
```

## 4. Manifiestos YAML

Los manifiestos se encuentran en la carpeta `k8s`:

- `namespace.yaml`
- `deployment-v1.yaml`
- `deployment-v2.yaml`
- `service.yaml`

## 5. Pasos realizados

1. Se preparo la imagen Docker del smart contract.
2. Se creo el namespace de Kubernetes.
3. Se desplego el Deployment inicial con 3 replicas.
4. Se creo un Service para agrupar los Pods.
5. Se verifico el estado de los Pods.
6. Se realizo el primer cambio en caliente: escalamiento de 3 a 5 replicas.
7. Se realizo el segundo cambio en caliente: actualizacion de imagen de version 1.0 a version 2.0.
8. Se verifico el historial de ReplicaSets y el estado del rollout.

## 6. Evidencias a insertar

Agregar capturas de pantalla de:

- `kubectl get pods -n $Namespace -o wide` antes del escalamiento.
- `kubectl get rs -n $Namespace` antes del escalamiento.
- `kubectl get pods -n $Namespace -o wide` despues de escalar a 5 replicas.
- `kubectl rollout status deployment/$DeploymentName -n $Namespace` despues del rolling update.
- `kubectl get rs -n $Namespace` despues del rolling update.
- Docker Hub mostrando las etiquetas `1.0` y `2.0`.

## 7. Conclusion

Con esta practica se demostro el uso de Kubernetes para orquestar un contenedor que incluye un smart contract. Se evidencio el despliegue inicial con 3 replicas, el escalamiento a 5 replicas y una actualizacion de imagen mediante rolling update.
"@

Write-Utf8NoBom (Join-Path $DocsPath "informe-tarea2-kubernetes.md") $reportMd
Write-Host "Informe base generado: docs/informe-tarea2-kubernetes.md" -ForegroundColor Green

Title "5. Preparando imagen 2.0 en Docker Hub"
if (-not $SkipDockerPush) {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-Host "Docker no esta instalado o no esta disponible en PATH." -ForegroundColor Red
        exit 1
    }

    Write-Host "Se va a crear la etiqueta 2.0 usando la imagen 1.0 existente." -ForegroundColor Yellow
    Write-Host "Si no has iniciado sesion en Docker Hub, ejecuta primero: docker login" -ForegroundColor Yellow
    $confirmDocker = Read-Host "Deseas hacer pull, tag y push de la imagen 2.0? Escribe SI"

    if ($confirmDocker -eq "SI") {
        docker pull $ImageV1
        docker tag $ImageV1 $ImageV2
        docker push $ImageV2
        Write-Host "Imagen 2.0 preparada en Docker Hub." -ForegroundColor Green
    } else {
        Write-Host "Se omitio la preparacion de imagen 2.0." -ForegroundColor Yellow
    }
} else {
    Write-Host "Se omitio Docker Push por parametro SkipDockerPush." -ForegroundColor Yellow
}

Title "6. Despliegue en Kubernetes"
if (-not $SkipKubernetesApply) {
    $kubectlCmd = Get-Command kubectl -ErrorAction SilentlyContinue
    if (-not $kubectlCmd) {
        Write-Host "kubectl no esta instalado o no esta disponible en PATH." -ForegroundColor Red
        Write-Host "Activa Kubernetes en Docker Desktop o instala kubectl." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Contexto actual de Kubernetes:" -ForegroundColor Yellow
    kubectl config current-context

    $confirmK8s = Read-Host "Deseas aplicar los YAML y ejecutar los cambios en Kubernetes? Escribe SI"

    if ($confirmK8s -eq "SI") {
        kubectl apply -f (Join-Path $K8sPath "namespace.yaml")
        kubectl apply -f (Join-Path $K8sPath "deployment-v1.yaml")
        kubectl apply -f (Join-Path $K8sPath "service.yaml")

        kubectl rollout status deployment/$DeploymentName -n $Namespace --timeout=180s
        Save-CommandOutput "kubectl get pods -n $Namespace -o wide" (Join-Path $EvidencePath "01_pods_inicial_3_replicas.txt")
        Save-CommandOutput "kubectl get rs -n $Namespace" (Join-Path $EvidencePath "02_replicasets_inicial.txt")
        Save-CommandOutput "kubectl get svc -n $Namespace" (Join-Path $EvidencePath "03_servicio.txt")

        Write-Host "Primer cambio en caliente: escalar de 3 a 5 replicas." -ForegroundColor Yellow
        kubectl scale deployment/$DeploymentName --replicas=5 -n $Namespace
        kubectl rollout status deployment/$DeploymentName -n $Namespace --timeout=180s
        Save-CommandOutput "kubectl get pods -n $Namespace -o wide" (Join-Path $EvidencePath "04_pods_despues_escalar_5.txt")
        Save-CommandOutput "kubectl get rs -n $Namespace" (Join-Path $EvidencePath "05_replicasets_despues_escalar.txt")

        Write-Host "Segundo cambio en caliente: rolling update a imagen 2.0." -ForegroundColor Yellow
        kubectl apply -f (Join-Path $K8sPath "deployment-v2.yaml")
        kubectl rollout status deployment/$DeploymentName -n $Namespace --timeout=240s
        Save-CommandOutput "kubectl get pods -n $Namespace -o wide" (Join-Path $EvidencePath "06_pods_despues_rolling_update.txt")
        Save-CommandOutput "kubectl get rs -n $Namespace" (Join-Path $EvidencePath "07_replicasets_despues_rolling_update.txt")
        Save-CommandOutput "kubectl rollout history deployment/$DeploymentName -n $Namespace" (Join-Path $EvidencePath "08_rollout_history.txt")
        Save-CommandOutput "kubectl describe deployment $DeploymentName -n $Namespace" (Join-Path $EvidencePath "09_describe_deployment.txt")

        Write-Host "Despliegue y evidencias TXT generadas correctamente." -ForegroundColor Green
    } else {
        Write-Host "Se omitio la aplicacion en Kubernetes." -ForegroundColor Yellow
    }
} else {
    Write-Host "Se omitio Kubernetes Apply por parametro SkipKubernetesApply." -ForegroundColor Yellow
}

Title "7. Estado de archivos creados"
Write-Host "Archivos de Kubernetes:" -ForegroundColor Yellow
Get-ChildItem $K8sPath
Write-Host ""
Write-Host "Evidencias generadas:" -ForegroundColor Yellow
Get-ChildItem $EvidencePath -ErrorAction SilentlyContinue

Title "8. Siguiente paso recomendado"
Write-Host "1. Tomar capturas de pantalla de Docker Desktop, Docker Hub y kubectl." -ForegroundColor White
Write-Host "2. Revisar docs/informe-tarea2-kubernetes.md y agregar capturas." -ForegroundColor White
Write-Host "3. Subir k8s/, docs/ y README actualizado a GitHub." -ForegroundColor White
Write-Host "4. Exportar el informe a PDF para adjuntarlo en la plataforma." -ForegroundColor White

Write-Host ""
Write-Host "Repositorio GitHub esperado:" -ForegroundColor Yellow
Write-Host "https://github.com/aalejos3626/smartcontract_docker_Andres_Alejandro_Silva_Aguilar" -ForegroundColor Cyan
Write-Host ""
Write-Host "Docker Hub esperado:" -ForegroundColor Yellow
Write-Host "https://hub.docker.com/r/$DockerHubUser/$ImageName" -ForegroundColor Cyan
