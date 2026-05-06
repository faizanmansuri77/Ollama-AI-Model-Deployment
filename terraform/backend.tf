terraform {
  backend "s3" {
    bucket = "ollama-app-tf-kubernetes-project" 
    key    = "EKS/terraform.tfstate"
    region = "ap-south-1"
  }
}
