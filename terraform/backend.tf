# backend.tf
terraform {
  backend "s3" {
    bucket = "my-demo-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "eu-north-1"
    # dynamodb_table = "my-demo-state-lock" # Якщо є
  }
}