# One small EC2 instance runs the app container.
# - private subnet, NO public IP, no load balancer
# - Orca side-scans the EBS volume and discovers the running container, which
#   becomes a container asset (static reachability + container->Dockerfile Code Origin)

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  image_uri = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
  registry  = split("/", aws_ecr_repository.app.repository_url)[0]
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  # A systemd unit retries login/pull/run every 30s, so it does not matter
  # whether the image is pushed before or after `terraform apply`.
  user_data_replace_on_change = true
  user_data                   = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf install -y docker
    systemctl enable --now docker

    cat >/etc/systemd/system/orca-appsec-demo.service <<'UNIT'
    [Unit]
    Description=orca-appsec-demo container
    After=docker.service network-online.target
    Requires=docker.service

    [Service]
    Restart=always
    RestartSec=30
    ExecStartPre=-/usr/bin/docker rm -f orca-appsec-demo
    ExecStartPre=/bin/sh -c 'aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${local.registry}'
    ExecStartPre=/usr/bin/docker pull ${local.image_uri}
    ExecStart=/usr/bin/docker run --name orca-appsec-demo -p 8080:8080 ${local.image_uri}
    ExecStop=/usr/bin/docker stop orca-appsec-demo

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now orca-appsec-demo.service
  EOT

  tags = { Name = "${var.name}-app" }
}
