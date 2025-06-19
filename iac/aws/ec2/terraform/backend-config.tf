terraform {
  backend "s3" {
    bucket  = "xpress-erpnext-terraform-state-296cc084"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
