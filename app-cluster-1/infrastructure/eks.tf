resource "aws_eks_cluster" "app_cluster_01" {
    name     = "app-cluster-01"
    role_arn = "arn:aws:iam::829007908826:role/eks-cluster-iam-role"
    version  = "1.31"

    vpc_config {
        subnet_ids = [
            aws_subnet.app_vpc_public_subnets.id, # public
            aws_subnet.app_vpc_public_subnets_2.id, # public
            aws_subnet.app_vpc_private_subnets.id, # private
            aws_subnet.app_vpc_private_subnets_2.id  # private
        ]
        endpoint_public_access  = true
        endpoint_private_access = true
    }
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
    url = aws_eks_cluster.app_cluster_01.identity[0].oidc[0].issuer

    client_id_list = [
        "sts.amazonaws.com"
    ]

    thumbprint_list = [
        "9e99a48a9960b14926bb7f3b02e22da0ecd6c7e5"
    ]
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
    cluster_name             = aws_eks_cluster.app_cluster_01.name
    addon_name               = "eks-pod-identity-agent"
    service_account_role_arn = "arn:aws:iam::829007908826:role/eks-pod-identity-role"

    depends_on = [
        aws_eks_cluster.app_cluster_01
    ]
}

resource "aws_eks_addon" "aws_secrets_store_csi_driver_provider" {
    cluster_name             = aws_eks_cluster.app_cluster_01.name
    addon_name               = "aws-secrets-store-csi-driver-provider"
    service_account_role_arn = "arn:aws:iam::829007908826:role/eks-pod-identity-role"

    depends_on = [
        aws_eks_cluster.app_cluster_01
    ]
}

resource "aws_eks_pod_identity_association" "ums_pod_identity_deployment_sa" {
    cluster_name    = aws_eks_cluster.app_cluster_01.name
    namespace       = "ums-ns"
    service_account = kubernetes_service_account_v1.ums_pod_identity_deployment_sa.metadata[0].name
    role_arn        = "arn:aws:iam::829007908826:role/eks-pod-identity-role"

    depends_on = [
        aws_eks_addon.eks_pod_identity_agent,
        kubernetes_service_account_v1.ums_pod_identity_deployment_sa
    ]
}

resource "aws_eks_fargate_profile" "app_cluster_01_fargate_profile" {
    cluster_name           = aws_eks_cluster.app_cluster_01.name
    fargate_profile_name   = "app-cluster-01-fargate-profile"
    pod_execution_role_arn = "arn:aws:iam::829007908826:role/cluster-fargate-pod-execution-role"
    subnet_ids = [
        aws_subnet.app_vpc_private_subnets.id,
        aws_subnet.app_vpc_private_subnets_2.id
    ]

    selector {
        namespace = "app2-fargate-ns"
    }

    depends_on = [
        aws_eks_cluster.app_cluster_01,
        kubernetes_namespace_v1.app2_fargate_ns
    ]
}

resource "aws_eks_node_group" "app_cluster_01_ng_private1" {
    cluster_name    = aws_eks_cluster.app_cluster_01.name
    node_group_name = "app-cluster-01-ng-private1"
    node_role_arn   = "arn:aws:iam::829007908826:role/cluster-ng-private1-role"
    subnet_ids = [
        aws_subnet.app_vpc_private_subnets.id, # private
        aws_subnet.app_vpc_private_subnets_2.id  # private
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

# resource "aws_eks_node_group" "app_cluster_01_ng_public1" {
#     cluster_name    = aws_eks_cluster.app_cluster_01.name
#     node_group_name = "app-cluster-01-ng-public1"
#     node_role_arn   = "arn:aws:iam::829007908826:role/cluster-ng-private1-role"
#     subnet_ids = [
#         aws_subnet.app_vpc_public_subnets.id, # public
#         aws_subnet.app_vpc_public_subnets_2.id, # public
#     ]
#     instance_types = ["t3.2xlarge"]
#     disk_size      = 20

#     scaling_config {
#         desired_size = 2
#         min_size     = 2
#         max_size     = 4
#     }

#     remote_access {
#         ec2_ssh_key = "my-vpc-01-keypair"
#     }

#     depends_on = [
#         aws_iam_role_policy_attachment.eks_nodegroup_worker_node_policy,
#         aws_iam_role_policy_attachment.eks_nodegroup_cni_policy,
#         aws_iam_role_policy_attachment.eks_nodegroup_ecr_readonly,
#         aws_iam_role_policy_attachment.eks_nodegroup_asg_access,
#         aws_iam_role_policy_attachment.eks_nodegroup_external_dns_access,
#         aws_iam_role_policy_attachment.eks_nodegroup_full_ecr_access,
#         # aws_iam_role_policy_attachment.eks_nodegroup_appmesh_access,
#         aws_iam_role_policy_attachment.eks_nodegroup_alb_ingress_access
#     ]
# }