provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}

data "aws_eks_cluster" "platform_cluster" {
  name = aws_eks_cluster.platform_cluster.name
}

data "aws_eks_cluster_auth" "platform_cluster" {
  name = aws_eks_cluster.platform_cluster.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.platform_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.platform_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.platform_cluster.token
}