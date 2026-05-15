# EKS + Jenkins + Terraform Deployment Guide

Repository:
urlfaizanmansuri77/Ollama GitHub Repositoryhttps://github.com/faizanmansuri77/Ollama.git

---

# Updated Architecture

This deployment architecture is optimized for AWS EKS 1.35 using Terraform and Jenkins CI/CD.

## Stack

- React Frontend
- FastAPI Backend
- Ollama LLM Service
- Amazon EKS 1.35
- Terraform Infrastructure as Code
- Jenkins CI/CD Pipeline
- Docker + Amazon ECR
- AWS Load Balancer Controller
- NGINX Ingress

---

# Recommended Project Structure

```bash
Ollama/
│
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── frontend/
│   ├── src/
│   ├── package.json
│   └── Dockerfile
│
├── k8s/
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── ollama-deployment.yaml
│   ├── ingress.yaml
│   ├── backend-service.yaml
│   ├── frontend-service.yaml
│   └── ollama-service.yaml
│
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── eks.tf
│   ├── outputs.tf
│   └── versions.tf
│
├── Jenkinsfile
├── docker-compose.yml
└── README.md
```

---

# Backend Dockerfile

## backend/Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

# Frontend Dockerfile

## frontend/Dockerfile

```dockerfile
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM nginx:stable-alpine

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

---

# Docker Compose (Local Development)

## docker-compose.yml

```yaml
version: '3.9'

services:
  ollama:
    image: ollama/ollama
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama

  backend:
    build: ./backend
    container_name: backend
    ports:
      - "8000:8000"
    depends_on:
      - ollama
    environment:
      OLLAMA_BASE_URL: http://ollama:11434

  frontend:
    build: ./frontend
    container_name: frontend
    ports:
      - "3000:80"
    depends_on:
      - backend

volumes:
  ollama_data:
```

---

# Terraform Configuration

## terraform/versions.tf

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

## terraform/provider.tf

```hcl
provider "aws" {
  region = var.aws_region
}
```

---

## terraform/variables.tf

```hcl
variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "ollama-eks-cluster"
}
```

---

## terraform/vpc.tf

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "ollama-vpc"

  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

---

## terraform/eks.tf

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = "1.35"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["c7i-flex.large"]

      capacity_type = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "dev"
  }
}
```

---

## terraform/outputs.tf

```hcl
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
```

---

# Terraform Deployment Commands

```bash
cd terraform

terraform init
terraform plan
terraform apply -auto-approve
```

---

# Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name ollama-eks-cluster
```

---

# Kubernetes Namespace

## k8s/namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ollama-app
```

---

# Ollama Deployment

## k8s/ollama-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: ollama-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
      - name: ollama
        image: ollama/ollama:latest
        ports:
        - containerPort: 11434
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "8Gi"
            cpu: "4"
```

---

# Ollama Service

## k8s/ollama-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ollama-service
  namespace: ollama-app
spec:
  selector:
    app: ollama
  ports:
    - port: 11434
      targetPort: 11434
  type: ClusterIP
```

---

# Backend Deployment

## k8s/backend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: ollama-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: YOUR_ECR/backend:latest
        ports:
        - containerPort: 8000
        env:
        - name: OLLAMA_BASE_URL
          value: http://ollama-service:11434
```

---

# Backend Service

## k8s/backend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: ollama-app
spec:
  selector:
    app: backend
  ports:
    - port: 8000
      targetPort: 8000
  type: ClusterIP
```

---

# Frontend Deployment

## k8s/frontend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ollama-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: YOUR_ECR/frontend:latest
        ports:
        - containerPort: 80
```

---

# Frontend Service

## k8s/frontend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ollama-app
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

---

# Ingress Configuration

## k8s/ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ollama-ingress
  namespace: ollama-app
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: ollama.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

---

# Deploy Kubernetes Resources

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
```

---

# Create Amazon ECR Repositories

```bash
aws ecr create-repository --repository-name frontend

aws ecr create-repository --repository-name backend
```

---

# Jenkins Setup

Install:

- Docker
- kubectl
- AWS CLI
- Terraform
- Jenkins Plugins:
  - Docker Pipeline
  - Kubernetes CLI
  - AWS Credentials
  - Pipeline
  - Git

---

# Jenkins Credentials Required

## Add Credentials

### AWS Credentials

```text
ID: aws-creds
```

### DockerHub or ECR Credentials

```text
ID: docker-creds
```

### kubeconfig Secret

```text
ID: kubeconfig
```

---

# Jenkinsfile

## Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = 'YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com'
        FRONTEND_IMAGE = 'frontend'
        BACKEND_IMAGE = 'backend'
        CLUSTER_NAME = 'ollama-eks-cluster'
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/faizanmansuri77/Ollama.git'
            }
        }

        stage('Build Backend') {
            steps {
                sh 'docker build -t $BACKEND_IMAGE ./backend'
            }
        }

        stage('Build Frontend') {
            steps {
                sh 'docker build -t $FRONTEND_IMAGE ./frontend'
            }
        }

        stage('Login to ECR') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                    sh '''
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_REGISTRY
                    '''
                }
            }
        }

        stage('Push Images') {
            steps {
                sh '''
                docker tag $BACKEND_IMAGE:latest $ECR_REGISTRY/$BACKEND_IMAGE:latest
                docker tag $FRONTEND_IMAGE:latest $ECR_REGISTRY/$FRONTEND_IMAGE:latest

                docker push $ECR_REGISTRY/$BACKEND_IMAGE:latest
                docker push $ECR_REGISTRY/$FRONTEND_IMAGE:latest
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                    sh '''
                    aws eks update-kubeconfig \
                    --region $AWS_REGION \
                    --name $CLUSTER_NAME

                    kubectl apply -f k8s/
                    kubectl rollout restart deployment/backend -n ollama-app
                    kubectl rollout restart deployment/frontend -n ollama-app
                    '''
                }
            }
        }
    }
}
```

---

# Install NGINX Ingress Controller

```bash
kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

---

# Verify Deployment

```bash
kubectl get pods -n ollama-app

kubectl get svc -n ollama-app

kubectl get ingress -n ollama-app
```

---

# Recommended Improvements

## Production Improvements

### Add Horizontal Pod Autoscaler

```bash
kubectl autoscale deployment backend \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n ollama-app
```

### Add Persistent Storage for Ollama Models

Use:

- EBS CSI Driver
- PersistentVolumeClaim

### Add Monitoring

Recommended:

- Prometheus
- Grafana
- Loki
- Fluent Bit

### Add HTTPS

Use:

- cert-manager
- AWS ACM
- Route53

---

# Final Deployment Flow

```text
Developer Pushes Code
        ↓
GitHub Webhook Triggers Jenkins
        ↓
Jenkins Builds Docker Images
        ↓
Images Pushed to Amazon ECR
        ↓
Jenkins Deploys to EKS
        ↓
NGINX Ingress Exposes Application
        ↓
Users Access React Frontend
```

---

# Important Notes

- EKS Version Used: 1.35
- Worker Node Instance Type: c7i-flex.large
- Recommended AWS Region: ap-south-1
- Ollama Requires High Memory Usage
- GPU Nodes Can Be Added Later for Faster Inference

---

# Cleanup Resources

```bash
terraform destroy -auto-approve
```

