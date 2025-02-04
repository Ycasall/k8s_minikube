apiVersion: batch/v1
kind: CronJob
metadata:
  name: alerta-pods
spec:
  schedule: "*/10 * * * *"  # Se ejecuta cada 10 minutos
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: alerta-pods
            image: alpine:latest  # Imagen liviana de Alpine Linux
            command: ["/bin/sh", "-c"]
            args:
              - apk add --no-cache bash curl jq && 
                git clone -b v1.1.0 https://github.com/Ycasall/k8s_minikube.git &&
                chmod +x k8s_minikube/AlertaPod.sh &&
                ./k8s_minikube/AlertaPod.sh
          restartPolicy: OnFailure
