#!/bin/bash

AWS_REGION="us-east-1"
ECR_REPOSITORY="038996484549.dkr.ecr.us-east-1.amazonaws.com/simple-app1"  
APP_NAME="simple-app1"
CLUSTER_NAME="ecs-cluster-dev"
SERVICE_NAME="simple-app1-service"
TASK_EXECUTION_ROLE="arn:aws:iam::038996484549:role/ecsTaskExecutionRole-simple-app1"

IMAGE_TAG=$(openssl rand -hex 8)

echo "Construyendo la imagen de Docker con tag: $IMAGE_TAG"
docker build -t $APP_NAME:$IMAGE_TAG .

echo "Autenticando en ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY


FULL_IMAGE_URI="$ECR_REPOSITORY:$IMAGE_TAG"
docker tag $APP_NAME:$IMAGE_TAG $FULL_IMAGE_URI

echo "Haciendo push de la imagen al registro ECR: $FULL_IMAGE_URI"
docker push $FULL_IMAGE_URI

echo "Actualizando la task definition de ECS con la nueva imagen"

echo "Registrando la nueva definición de la tarea con AWS CLI"
aws ecs register-task-definition \
    --family $APP_NAME \
    --network-mode awsvpc \
    --execution-role-arn $TASK_EXECUTION_ROLE \
    --container-definitions "[
        {
            \"name\": \"$APP_NAME\",
            \"image\": \"$FULL_IMAGE_URI\",
            \"essential\": true,
            \"portMappings\": [
                {
                    \"containerPort\": 8000,
                    \"hostPort\": 8000
                }
            ],
            \"logConfiguration\": {
                \"logDriver\": \"awslogs\",
                \"options\": {
                    \"awslogs-group\": \"/ecs/$APP_NAME\",
                    \"awslogs-region\": \"$AWS_REGION\",
                    \"awslogs-stream-prefix\": \"ecs\"
                }
            },
            \"healthCheck\": {
                \"command\": [\"CMD-SHELL\", \"curl -f http://localhost:8000 || exit 1\"],
                \"interval\": 30,
                \"timeout\": 5,
                \"retries\": 3,
                \"startPeriod\": 60
            }
        }
    ]" \
    --requires-compatibilities FARGATE \
    --cpu "256" \
    --memory "512" \
    --region $AWS_REGION > /dev/null 2>&1

echo "Actualizando el servicio ECS con la nueva task definition"
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $AWS_REGION /dev/null 2>&1

echo "Pipeline completado con éxito."