########################################
# IAM Assume Role for EKS Cluster
########################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

########################################
# EKS Cluster Role
########################################

resource "aws_iam_role" "ollama_cluster" {
  name               = "ollama-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ollama_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.ollama_cluster.name
}

########################################
# Networking (Default VPC)
########################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# EKS Cluster
########################################

resource "aws_eks_cluster" "ollama" {
  name     = "ollama-cluster"
  role_arn = aws_iam_role.ollama_cluster.arn

  vpc_config {
    subnet_ids = data.aws_subnets.public.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.ollama_cluster_policy
  ]
}

########################################
# Node Group IAM Role
########################################

resource "aws_iam_role" "ollama_node" {
  name = "ollama-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ollama_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.ollama_node.name
}

resource "aws_iam_role_policy_attachment" "ollama_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.ollama_node.name
}

resource "aws_iam_role_policy_attachment" "ollama_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ollama_node.name
}

########################################
# Node Group
########################################

resource "aws_eks_node_group" "ollama" {
  cluster_name    = aws_eks_cluster.ollama.name
  node_group_name = "ollama-node-group"
  node_role_arn   = aws_iam_role.ollama_node.arn
  subnet_ids      = data.aws_subnets.public.ids

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["c7i-flex.large"]
  capacity_type  = "ON_DEMAND"

  depends_on = [
    aws_iam_role_policy_attachment.ollama_worker,
    aws_iam_role_policy_attachment.ollama_cni,
    aws_iam_role_policy_attachment.ollama_ecr
  ]
}

########################################
# OIDC Provider (REQUIRED for EBS CSI)
########################################

data "aws_eks_cluster" "ollama" {
  name = aws_eks_cluster.ollama.name
}

resource "aws_iam_openid_connect_provider" "ollama" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd6cbe4"]

  url = data.aws_eks_cluster.ollama.identity[0].oidc[0].issuer
}

########################################
# EBS CSI IAM Role (FIX PVC ISSUE)
########################################

data "aws_iam_policy_document" "ebs_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.ollama.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.ollama.arn]
    }
  }
}

resource "aws_iam_role" "ollama_ebs_csi" {
  name               = "ollama-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_assume.json
}

resource "aws_iam_role_policy_attachment" "ollama_ebs_policy" {
  role       = aws_iam_role.ollama_ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

########################################
# EBS CSI ADDON (CRITICAL)
########################################

resource "aws_eks_addon" "ollama_ebs_csi" {
  cluster_name             = aws_eks_cluster.ollama.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ollama_ebs_csi.arn

  depends_on = [
    aws_eks_node_group.ollama
  ]
}
