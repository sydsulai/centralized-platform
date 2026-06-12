variable "eks_pod_identity_role_action" {
  description = "Actions for the EKS pod identity role"
  type        = list(string)
}

variable "access_secret_policy_actions" {
  description = "Actions for accessing secrets in Secrets Manager"
  type        = list(string)
}