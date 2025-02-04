#!/bin/bash

# Configurar el perfil de AWS y asumir el rol antes de ejecutar cualquier comando de AWS
AWS_ROLE_ARN="arn:aws:iam::682380910661:role/Rol_Minikube"
CREDENTIALS=$(aws sts assume-role --role-arn "$AWS_ROLE_ARN" --role-session-name "SesionTemporal")

export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

# Variables
NAMESPACE="default"
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:682380910661:sns_minikube"
DEPLOYMENT_FILE="./k8s/deployment.yaml"
S3_BUCKET="minikube-logs"

# 📌 Validar conexión con S3
echo "🔍 Verificando acceso a S3..."
if aws s3 ls "s3://$S3_BUCKET" > /dev/null 2>&1; then
    echo "✅ Conexión a S3 exitosa."
else
    echo "❌ Error: No se pudo acceder al bucket S3: $S3_BUCKET"
    exit 1
fi

# 📌 Validar conexión con SNS
echo "🔍 Verificando acceso a SNS..."
if aws sns get-topic-attributes --topic-arn "$SNS_TOPIC_ARN" > /dev/null 2>&1; then
    echo "✅ Conexión a SNS exitosa."
else
    echo "❌ Error: No se pudo acceder al tópico SNS: $SNS_TOPIC_ARN"
    exit 1
fi

# Obtener el estado de los pods
pods=$(kubectl get pods -n $NAMESPACE --no-headers)

# Filtrar pods que no están en estado "Running"
non_running_pods=""
while read -r pod; do
    pod_name=$(echo $pod | awk '{print $1}')
    pod_status=$(echo $pod | awk '{print $3}')
    
    if [ "$pod_status" != "Running" ]; then
        non_running_pods="$non_running_pods$pod_name($pod_status)"
        
        # Obtener los logs del pod
        log_file="/tmp/${pod_name}_logs.txt"
        kubectl logs $pod_name -n $NAMESPACE > $log_file 2>&1
        
        # Subir los logs a S3
        aws s3 cp $log_file s3://$S3_BUCKET/${pod_name}_logs.txt
        
        # Eliminar el archivo temporal después de subirlo
        rm -f $log_file
    fi
done <<EOF
$pods
EOF

# Si hay pods que no están en estado "Running", enviar notificación y aplicar deployment.yaml
if [ -n "$non_running_pods" ]; then
    echo "Pods no en estado Running encontrados:"
    printf "$non_running_pods"

    # Construir el mensaje de notificación
    message="Los siguientes pods no están en estado Running:\n$non_running_pods"
    printf "$message"

    # Enviar notificación a SNS
    aws sns publish --topic-arn $SNS_TOPIC_ARN --message "$message" --subject "Alerta: Pods no en estado Running"

    # Aplicar el archivo deployment.yaml
    echo "Aplicando el archivo deployment.yaml..."
    kubectl apply -f $DEPLOYMENT_FILE -n $NAMESPACE
else
    echo "Todos los pods están en estado Running."
fi
