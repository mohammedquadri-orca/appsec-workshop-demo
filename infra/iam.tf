data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "data_bucket" {
  name        = "${var.name}-data-bucket"
  description = "App access to the demo data bucket"

  # ORCA-DEMO: IaC – wildcard action "s3:*" (scoped to the demo data bucket only, not "*")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DemoBucketFullAccess"
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = [module.storage.bucket_arn, "${module.storage.bucket_arn}/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "data_bucket" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.data_bucket.arn
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app"
  role = aws_iam_role.app.name
}
