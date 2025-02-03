📌 Descripción del Pipeline
Este pipeline automatiza el proceso de integración y despliegue continuo (CI/CD) para una aplicación web. Se activa automáticamente cuando hay cambios en las ramas main o develop y ejecuta una serie de tareas para clonar repositorios, verificar herramientas, construir imágenes, analizar código y desplegar la aplicación en un clúster de Minikube.
🚀 Trigger y PR (Pull Request)
trigger:
  branches:
    include:
      - main
      - develop

pr:
  branches:
    include:
      - main
      - develop

🔹 ¿Qué hace?
Ejecuta el pipeline automáticamente cuando hay cambios en main o develop.
Se activa también cuando se crea o actualiza un Pull Request en estas ramas.

🛠 Pasos del Pipeline
1️⃣ Clonar Repositorios
- script: |
    git clone https://github.com/Ycasall/personal-website.git
    git clone https://github.com/Ycasall/pipeline-templates.git
    ls -R pipeline-templates
  displayName: 'Clone repositories and check structure'
🔹 ¿Qué hace?
Clona el código fuente del proyecto (personal-website).
Clona los archivos de configuración y scripts del pipeline (pipeline-templates).
Verifica la estructura del repositorio clonado.

2️⃣ Verificar Instalación de Docker
- script: |
    docker --version
    docker run hello-world
    ls -l /var/run/docker.sock
  displayName: 'Verify Docker installation'
🔹 ¿Qué hace?
Confirma que Docker está instalado y funcionando correctamente.
Ejecuta un contenedor de prueba (hello-world).
Verifica los permisos de Docker en el sistema.

3️⃣ Iniciar Minikube con Docker como Driver
- script: |
    minikube start --driver=docker
  displayName: 'Start Minikube cluster'
🔹 ¿Qué hace?
Inicia un clúster de Kubernetes en Minikube usando Docker como motor de virtualización.
Es necesario para desplegar y probar la aplicación en un entorno local de Kubernetes.

4️⃣ Configurar kubectl para Minikube
- script: |
    kubectl config use-context minikube
  displayName: 'Set kubeconfig'
🔹 ¿Qué hace?
Configura kubectl para conectarse al clúster de Minikube, permitiendo la gestión de pods, servicios y despliegues.
