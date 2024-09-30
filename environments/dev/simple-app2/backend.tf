terraform {
  backend "s3" {
    bucket         = "BUCKETTERRAFORM"
    key            = "dev/simple-app1/terraform.tfstate"
    region         = "REGION"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}