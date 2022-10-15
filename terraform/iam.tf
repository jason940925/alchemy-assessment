data "aws_iam_policy_document" "cluster_admin_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:root"
      ]
    }
  }
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_admin" {
  name               = "${var.account_name}-eks-admin"
  assume_role_policy = data.aws_iam_policy_document.cluster_admin_role_policy.json
}

resource "aws_iam_role_policy" "cluster_admin" {
  name = "eks-admin-policy"
  role = aws_iam_role.cluster_admin.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "eks:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "iam:GetRole",
          "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "cluster_admin" {
  name = "eks_cluster_admin"
  role = aws_iam_role.cluster_admin.name
}