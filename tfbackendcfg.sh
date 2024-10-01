#!/bin/bash

read -p "Ingrese el nombre del bucket a crear: " TFBUCKET
read -p "Ingrese la región (por ejemplo, us-east-1): " REGION

echo "Nombre del bucket: $TFBUCKET"
echo "Región: $REGION"

aws s3api create-bucket --bucket $TFBUCKET --region $REGION


aws s3api put-bucket-versioning --bucket $TFBUCKET --versioning-configuration Status=Enabled

aws dynamodb create-table \
    --table-name terraform-lock-table \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 > /dev/null 2>&1

echo "Bucket de S3 y tabla de DynamoDB creados correctamente."

FILES=(
    "environments/dev/_global/backend.tf"
    "environments/dev/_global/main.tf"
    "environments/dev/simple-app1/backend.tf"
    "environments/dev/simple-app1/main.tf"
    "environments/dev/simple-app2/backend.tf"
    "environments/dev/simple-app2/main.tf"
)

for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        sed -i "s/BUCKETTERRAFORM/$TFBUCKET/g" "$file"
        sed -i "s/REGION/$REGION/g" "$file"
        echo "Se actualizó el archivo: $file"
    else
        echo "Archivo no encontrado: $file"
    fi
done