data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks]
  name       = local.cluster_name
}