terraform {
  backend "s3" {
    bucket         = "BUCKETTERRAFORM" 
    key            = "dev/global/terraform.tfstate"   
    region         = "REGION"                 
    dynamodb_table = "terraform-lock-table"      
    encrypt        = true                       
  }
}