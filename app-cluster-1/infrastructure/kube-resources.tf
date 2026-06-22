resource "kubernetes_namespace_v1" "ums_ns" {
  metadata {
    name = "ums-ns"
    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [
    aws_eks_cluster.app_cluster_01
  ]
}

resource "kubernetes_namespace_v1" "app2_fargate_ns" {
  metadata {
    name = "app2-fargate-ns"
  }

  depends_on = [
    aws_eks_cluster.app_cluster_01
  ]
}

resource "kubernetes_namespace_v1" "default_ns" {
  metadata {
    name = "default"
    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [
    aws_eks_cluster.app_cluster_01
  ]
}

resource "kubernetes_service_account_v1" "ums_pod_identity_deployment_sa" {
    metadata {
        name      = "ums-pod-identity-deployment-sa"
        namespace = "ums-ns"
    }

    depends_on = [
        aws_eks_cluster.app_cluster_01,
        kubernetes_namespace_v1.ums_ns
    ]
}

resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
    metadata {
        name      = "aws-load-balancer-controller"
        namespace = "kube-system"
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller_app_irsa.arn
        }
    }

    depends_on = [
        aws_eks_cluster.app_cluster_01,
        aws_iam_role_policy_attachment.aws_load_balancer_controller_app_irsa_policy_attachment
    ]
}

resource "kubernetes_service_account_v1" "xray_daemon" {
    metadata {
        name      = "xray-daemon"
        namespace = "default"
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.xray_daemon_app_irsa.arn
        }
    }

    depends_on = [
        aws_eks_cluster.app_cluster_01,
        aws_iam_role_policy_attachment.xray_daemon_app_irsa_policy_attachment
    ]
}