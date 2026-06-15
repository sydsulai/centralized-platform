resource "aws_eks_cluster" "platform_cluster" {
  name     = "platform-cluster"
  role_arn = "arn:aws:iam::829007908826:role/eks-cluster-iam-role"
  version  = "1.31"

  vpc_config {
    subnet_ids = [
      aws_subnet.platform_vpc_public_subnets.id,
      aws_subnet.platform_vpc_public_subnets_2.id,
      aws_subnet.platform_vpc_private_subnets.id,
      aws_subnet.platform_vpc_private_subnets_2.id,
    ]
    endpoint_public_access  = true
    endpoint_private_access = true
  }
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = aws_eks_cluster.platform_cluster.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da0ecd6c7e5",
  ]
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name             = aws_eks_cluster.platform_cluster.name
  addon_name               = "eks-pod-identity-agent"
  service_account_role_arn = "arn:aws:iam::829007908826:role/eks-pod-identity-role"

  depends_on = [
    aws_eks_cluster.platform_cluster,
  ]
}

resource "aws_eks_pod_identity_association" "eks_pod_identity_agent_association" {
  cluster_name    = aws_eks_cluster.platform_cluster.name
  namespace       = "default"
  service_account = "eks-pod-identity-agent"
  role_arn        = "arn:aws:iam::829007908826:role/eks-pod-identity-role"

  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
  ]
}

resource "aws_eks_fargate_profile" "platform_cluster_fargate_profile" {
  cluster_name           = aws_eks_cluster.platform_cluster.name
  fargate_profile_name   = "platform-cluster-fargate-profile"
  pod_execution_role_arn = "arn:aws:iam::829007908826:role/cluster-fargate-pod-execution-role"
  subnet_ids = [
    aws_subnet.platform_vpc_private_subnets.id,
    aws_subnet.platform_vpc_private_subnets_2.id,
  ]

  selector {
    namespace = "default"
  }

  depends_on = [
    aws_eks_cluster.platform_cluster,
  ]
}

resource "aws_eks_node_group" "platform_cluster_ng_private1" {
  cluster_name    = aws_eks_cluster.platform_cluster.name
  node_group_name = "platform-cluster-ng-private1"
  node_role_arn   = "arn:aws:iam::829007908826:role/cluster-ng-private1-role"
  subnet_ids = [
    aws_subnet.platform_vpc_private_subnets.id,
    aws_subnet.platform_vpc_private_subnets_2.id,
  ]
  instance_types = ["t3.2xlarge"]
  disk_size      = 20

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  remote_access {
    ec2_ssh_key = "my-vpc-01-keypair"
  }
}
