# 🚀 Deployment Guide: AI Agent on AWS EKS using Terraform & Kubernetes

This guide explains how to deploy the **FastAPI + React + Ollama AI Application** on an **Amazon EKS (Elastic Kubernetes Service)** cluster using:

* **Terraform** → Infrastructure Provisioning
* **Docker** → Containerization
* **Kubernetes** → Container Orchestration
* **AWS EKS** → Managed Kubernetes Cluster
* **AWS ECR** → Docker Image Registry
* **AWS Load Balancer Controller** → External Access

This deployment setup follows a real-world DevOps workflow suitable for production-style environments.

---

# 📌 Architecture Overview

```text
User
  ↓
AWS Load Balancer
  ↓
Frontend Service (React + Vite)
  ↓
Backend Service (FastAPI)
  ↓
Ollama Service (LLaMA 3.2 Model)
```

---

# 📋 Prerequisites

Before starting, ensure you have:

* AWS Account
* Ubuntu/Linux Machine or EC2 Instance
* IAM User with AdministratorAccess
* AWS CLI configured
* Terraform installed
* kubectl installed
* Docker installed

---

# 🏗 Step 1: Create Project Structure

```bash
AI-Agent-EKS/
│
├── terraform/
│   ├── provider.tf
│   ├── vpc.tf
│   ├── eks.tf
│   ├── nodegroup.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── k8s/
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── ollama-deployment.yaml
│   ├── ollama-service.yaml
│   ├── ingress.yaml
│   ├── storageclass.yaml
│   └── pvc.yaml
│
├── backend/
├── frontend/
└── README.md
```

---

# ⚙️ Step 2: Install Required Tools

## Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

sudo ./aws/install
```

Configure AWS:

```bash
aws configure
```

---

## Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

---

## Install Terraform

```bash
wget https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip

unzip terraform_1.8.5_linux_amd64.zip

sudo mv terraform /usr/local/bin/
```

---

# ☁️ Step 3: Terraform Configuration

## provider.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.51"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

---

## vpc.tf

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "eks-vpc"

  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}
```

---

## eks.tf

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "ai-agent-cluster"
  cluster_version = "1.35"

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    worker_nodes = {
      instance_types = ["c7i-flex.large"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}
```

---

## outputs.tf

```hcl
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
```

---

# 🚀 Step 4: Deploy Infrastructure

Initialize Terraform:

```bash
cd terraform

terraform init
```

Validate:

```bash
terraform validate
```

Plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply -auto-approve
```

---

# 🔗 Step 5: Connect kubectl to EKS

```bash
aws eks update-kubeconfig \
--region ap-south-1 \
--name ai-agent-cluster
```

Verify:

```bash
kubectl get nodes
```

---

# 🐳 Step 6: Build & Push Docker Images

## Create AWS ECR Repositories

```bash
aws ecr create-repository \
--repository-name ai-backend

aws ecr create-repository \
--repository-name ai-frontend
```

---

## Login to ECR

```bash
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS \
--password-stdin <aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com
```

---

## Build Backend Image

```bash
cd backend

docker build -t ai-backend .

docker tag ai-backend:latest \
<aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com/ai-backend:latest

docker push \
<aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com/ai-backend:latest
```

---

## Build Frontend Image

```bash
cd frontend

docker build -t ai-frontend .

docker tag ai-frontend:latest \
<aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com/ai-frontend:latest

docker push \
<aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com/ai-frontend:latest
```

---

# ☸️ Step 7: Kubernetes Manifests

## namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ai-agent
```

---

## backend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: ai-agent

spec:
  replicas: 1

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

        image: orionpax77/ollama:backend

        ports:
        - containerPort: 5000
```

---

## backend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: ai-agent

spec:
  selector:
    app: backend

  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000

  type: ClusterIP
```

---

## frontend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ai-agent

spec:
  replicas: 1

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

        image: orionpax77/ollama:frontend

        ports:
        - containerPort: 5173
```

---

## frontend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ai-agent

spec:
  selector:
    app: frontend

  ports:
    - protocol: TCP
      port: 80
      targetPort: 5173

  type: LoadBalancer
```

---

# 🤖 Step 8: Deploy Ollama in Kubernetes

## ollama-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: ai-agent

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

        volumeMounts:
        - name: ollama-storage
          mountPath: /root/.ollama

      volumes:
      - name: ollama-storage
        persistentVolumeClaim:
          claimName: ollama-pvc
```

---

## pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ollama-pvc
  namespace: ai-agent

spec:
  accessModes:
    - ReadWriteOnce

  resources:
    requests:
      storage: 20Gi

  storageClassName: gp3
```

---

## ollama-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ollama-service
  namespace: ai-agent

spec:
  selector:
    app: ollama

  ports:
    - port: 11434
      targetPort: 11434

  type: ClusterIP
```

---

# 📦 Step 9: Apply Kubernetes Manifests

```bash
kubectl apply -f k8s/
```

Verify:

```bash
kubectl get pods -n ai-agent

kubectl get svc -n ai-agent
```

---

# 🌐 Step 10: Access Application

Get LoadBalancer URL:

```bash
kubectl get svc -n ai-agent
```

Open:

```text
http://<external-load-balancer>
```

---

# 📊 Useful Kubernetes Commands

## View Pods

```bash
kubectl get pods -n ai-agent
```

## View Services

```bash
kubectl get svc -n ai-agent
```

## Check Logs

```bash
kubectl logs <pod-name> -n ai-agent
```

## Describe Pod

```bash
kubectl describe pod <pod-name> -n ai-agent
```

## Restart Deployment

```bash
kubectl rollout restart deployment backend -n ai-agent
```

---

# 🛠 Troubleshooting

## PVC Pending

Install EBS CSI Driver:

```bash
eksctl utils associate-iam-oidc-provider \
--region ap-south-1 \
--cluster ai-agent-cluster \
--approve
```

---

## LoadBalancer Pending

Install AWS Load Balancer Controller.

---

## ImagePullBackOff

Check:

* ECR image URL
* IAM permissions
* Image exists in ECR

---

# ✅ Final Result

After successful deployment:

* Frontend runs on EKS
* Backend API runs on EKS
* Ollama runs inside Kubernetes
* Storage persists using EBS
* Application is accessible using AWS LoadBalancer
