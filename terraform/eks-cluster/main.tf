data "aws_subnet" "private_selected" {
  vpc_id = module.vpc.vpc_id
  availability_zone = "us-east-1b"

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }

  depends_on = [ module.vpc ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name    = "eks-${var.env}"
  cluster_version = "1.24"

  cluster_endpoint_public_access  = true # TEST ONLY
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = [] # empty to force each nodegroup to configure it
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"

    #subnet_ids = module.vpc.private_subnets # by default, we use private subnets
    subnet_ids = [data.aws_subnet.private_selected.id] # by default, we use private subnets

    network_interfaces = [
      {
        associate_public_ip_address = false # by default, we disable public IPs
      }
    ]
  }

  eks_managed_node_groups = {
    apps = {
      min_size     = 1
      max_size     = 2
      desired_size = 2

      disk_size = 20

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT"
    }
  }

  create_kms_key = false
  kms_key_deletion_window_in_days = 7
  cluster_encryption_config = {}

  create_cloudwatch_log_group = false # disable cloudwatch logging
  cluster_enabled_log_types = [] # disable cloudwatch logging

  manage_aws_auth_configmap = true # MUST be true to make the ec2 nodes reachable
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"
      username = ""
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions"
      username = ""
      groups   = ["github-actions"]
    }
  ]

  tags = var.tags
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec { # workaround required because of aws-auth creation bug
    command     = "aws"
    api_version = "client.authentication.k8s.io/v1beta1"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

resource "kubernetes_cluster_role" "github_actions" {
  metadata {
    name = "github-actions"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "create"]
  }
}

resource "kubernetes_role" "github_actions" {
  metadata {
    name = "github-actions"
    namespace = "website"
  }

  rule{
    api_groups = [
      ""
    ]
    resources = [
      "configmaps",
      "services",
      "secrets"
    ]
    verbs = [
      "get",
      "create",
      "delete",
      "patch",
      "update",
      "list"
    ]
  }
  rule{
    api_groups = [
      "apps"
    ]
    resources = [
      "deployments",
      "deployments/rollback",
      "deployments/scale",
      "statefulsets",
      "statefulsets/scale"
    ]
    verbs = [
      "get",
      "create",
      "delete",
      "patch",
      "update"
    ]
  }
}

resource "kubernetes_cluster_role_binding" "github_actions" {
  metadata {
    name = "github-actions"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "github-actions"
  }

  subject {
    kind      = "Group"
    name      = "github-actions"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role_binding" "github_actions" {
  metadata {
    name = "github-actions"
    namespace = "website"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "github-actions"
  }

  subject {
    kind      = "Group"
    name      = "github-actions"
    api_group = "rbac.authorization.k8s.io"
  }
}