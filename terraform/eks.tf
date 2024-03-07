locals {
  cluster_name    = "main"
  cluster_version = "1.29"
  region          = var.aws_region

}


################################################################################
# EKS Module
################################################################################

data "aws_iam_policy_document" "ssm" {

  statement {
    sid    = "EnableAccessViaSSMSessionManager"
    effect = "Allow"
    actions = [
      "ssmmessages:OpenDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:CreateControlChannel",
      "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EnableSSMRunCommand"
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ec2messages:SendReply",
      "ec2messages:GetMessages",
      "ec2messages:GetEndpoint",
      "ec2messages:FailMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:AcknowledgeMessage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm" {
  policy = data.aws_iam_policy_document.ssm.json
  name   = "SSMManagedNode"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.5.0"

  cluster_name                    = local.cluster_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
  }

  cluster_encryption_config = {
    resources = ["secrets"]
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  enable_cluster_creator_admin_permissions = true

  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/faq.md#i-received-an-error-expect-exactly-one-securitygroup-tagged-with-kubernetesioclustername-
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = null
  }


  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]

    attach_cluster_primary_security_group = true
    iam_role_additional_policies = {
      "SSMManagedNode" : aws_iam_policy.ssm.arn
    }

    vpc_security_group_ids = []

    # idealy only create nodes in private subnets
    subnet_ids = concat(module.vpc.private_subnets)
  }

  eks_managed_node_groups = {
    node = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["m6i.large"]
      labels = {
        Environment = var.environment
      }

    }
  }
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
}

