#!/bin/bash

# Variables comunes
AWS_REGION="us-east-1"
APPS=("simple-app1" "simple-app2")

for APP_NAME in "${APPS[@]}"; do
    echo "Configurando $APP_NAME..."

    # Crear el repositorio ECR para la aplicación
    echo "Creando el repositorio ECR para $APP_NAME..."
    REPO_URI=$(aws ecr create-repository --repository-name $APP_NAME --region $AWS_REGION --query 'repository.repositoryUri' --output text)
    echo "Repositorio ECR creado: $REPO_URI"

    echo "Creando el log group /ecs/$APP_NAME"
    aws logs create-log-group --log-group-name "/ecs/$APP_NAME" --region $AWS_REGION 

    TF_PATH="./environments/dev/$APP_NAME"
    ROLE_ARN=$(terraform -chdir=$TF_PATH output -raw task_execution_role)

    # Ruta del pipeline.sh de la aplicación
    PIPELINE_FILE="./${APP_NAME}/pipeline.sh"

    # Reemplazar los valores en el pipeline.sh
    if [[ -f "$PIPELINE_FILE" ]]; then
        echo "Actualizando $PIPELINE_FILE con el nuevo repositorio y rol..."
        sed -i "s|ECRURI|$REPO_URI|g" "$PIPELINE_FILE"
        sed -i "s|TASKROLE|$ROLE_ARN|g" "$PIPELINE_FILE"
        echo "$PIPELINE_FILE ha sido actualizado correctamente."
    else
        echo "Advertencia: No se encontró el archivo pipeline.sh para $APP_NAME en la ruta esperada."
    fi
done

echo "El script ha terminado de configurar los repositorios ECR, roles y pipelines para ambas aplicaciones."
