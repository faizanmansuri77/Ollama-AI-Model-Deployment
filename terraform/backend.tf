terraform {
  backend "s3" {
    bucket = "ollama-app-tf-kubernetes-project" 
    key    = "ollama-app/terraform.tfstate"
    region = "ap-south-1"
  }
}
