#!/bin/bash

""
set -e

echo "Iniciando configuración del backend S3 y DynamoDB..."
./tfbackendcfg.sh

echo "Desplegando infraestructura global de Terraform..."
cd environments/dev/_global
terraform init
terraform apply -auto-approve

echo "Desplegando infraestructura de simple-app1..."
cd ../simple-app1
terraform init
terraform apply -auto-approve

echo "Desplegando infraestructura de simple-app2..."
cd ../simple-app2
terraform init
terraform apply -auto-approve


cd ../../../

echo "Configurando ECR y roles para cada aplicación..."
./pipelineconfig.sh

echo "Iniciando el despliegue de simple-app1..."
cd simple-app1
./pipeline.sh

echo "Iniciando el despliegue de simple-app2..."
cd ../simple-app2
./pipeline.sh

echo "Despliegue completado con éxito."

cd ..

TF_PATH="./environments/dev/simple-app1"
ALB_DNS=$(terraform -chdir=$TF_PATH output -raw alb_dns_name)
echo "Simple-app1 http://$ALB_DNS"
TF_PATH="./environments/dev/simple-app2"
ALB_DNS=$(terraform -chdir=$TF_PATH output -raw alb_dns_name)
echo "Simple-app2 http://$ALB_DNS"