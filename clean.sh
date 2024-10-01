#!/bin/bash

AWSREGION="us-east-1"
TFBUCKET="terraform-state-bucket-23589742"
TABLADYAMO="terraform-lock-table"

set -e

echo "Destruyendo recursos en environments/dev/simple-app1..."
cd environments/dev/simple-app1
terraform init -input=false
terraform destroy -auto-approve


echo "Destruyendo recursos en environments/dev/simple-app2..."
cd ../simple-app2
terraform init -input=false
terraform destroy -auto-approve


echo "Destruyendo recursos en environments/dev/_global..."
cd ../_global
terraform init -input=false
terraform destroy -auto-approve

echo "Eliminando repositorios ECR"

aws ecr delete-repository --repository-name simple-app1 --region $AWSREGION --force
aws ecr delete-repository --repository-name simple-app2 --region $AWSREGION --force

echo "Eliminando log groups"

aws logs delete-log-group --log-group-name /ecs/simple-app1 --region $AWSREGION
aws logs delete-log-group --log-group-name /ecs/simple-app2 --region $AWSREGION

echo "Eliminando bucket de tf state"

aws s3 rm s3://$TFBUCKET --recursive --region $AWSREGION
aws s3api delete-bucket --bucket $TFBUCKET --region $AWSREGION

echo "Eliminando tabla dynamoDB"

aws dynamodb delete-table --table-name $TABLADYAMO --region $AWSREGION

echo "Destrucción de la infraestructura completada."
