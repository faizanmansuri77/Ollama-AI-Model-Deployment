########################################
# Provider
########################################
provider "aws" {
  region = "ap-south-1"
}

########################################
# Get Default VPC & Subnets
########################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# IAM Role for EKS Cluster
########################################
resource "aws_iam_role" "eks_cluster_role" {
  name = "ollama-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

########################################
# EKS Cluster
########################################
resource "aws_eks_cluster" "eks_cluster" {
  name     = "ollama-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

########################################
# IAM Role for Node Group
########################################
resource "aws_iam_role" "eks_node_role" {
  name = "ollama-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

########################################
# EKS Node Group
########################################
resource "aws_eks_node_group" "ollama_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "ollama-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["c7i-flex.large"]

  capacity_type = "ON_DEMAND"

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy
  ]
}

########################################
# OPTIONAL: RDS (Remove if not needed)
########################################

resource "aws_security_group" "rds_sg" {
  name   = "ollama-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠ Restrict in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "ollama-rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "mariadb" {
  identifier             = "ollama-mariadb"
  allocated_storage      = 20
  engine                 = "mariadb"
  engine_version         = "11.4"
  instance_class         = "db.t4g.micro"

  db_name  = "ollamadb"
  username = "admin"
  password = "StrongPassword123!"   # 🔴 Change this

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true
  skip_final_snapshot = true
  multi_az            = false
}

########################################
# Outputs
########################################
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.mariadb.address
}

output "rds_port" {
  value = aws_db_instance.mariadb.port
}
