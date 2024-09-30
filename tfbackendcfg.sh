#!/bin/bash

#TFBUCKET="terraform-state-bucket-2358974"
REGION="us-east-1"

read -p "Ingrese nombre del bucket a crear: " TFBUCKET
read -p "Ingrese region: " REGION

echo $TFBUCKET $REGION

#aws s3api create-bucket --bucket $TFBUCKET --region $REGION

#aws s3api put-bucket-versioning --bucket $TFBUCKET --versioning-configuration Status=Enabled

#aws dynamodb create-table \
#    --table-name terraform-lock-table \
#    --attribute-definitions AttributeName=LockID,AttributeType=S \
#    --key-schema AttributeName=LockID,KeyType=HASH \
#    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5