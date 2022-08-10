resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"

  vpc_security_group_ids      = [aws_security_group.main.id]
  iam_instance_profile        = "AmazonSSMRoleForInstancesQuickSetup"
  subnet_id                   = local.pub_subnet
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name

  user_data = <<-EOT
  #!/bin/sh
  export K3S_TOKEN='${random_password.cluster_token.result}'
  export AWS_TOKEN=$(curl -fsS "http://169.254.169.254/latest/api/token" -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  export PUBLIC_IP=$(curl -fsS "http://169.254.169.254/latest/meta-data/public-ipv4" -H "X-aws-ec2-metadata-token: $AWS_TOKEN")
  export INSTALL_K3S_EXEC="--tls-san $PUBLIC_IP"
  curl -sfL https://get.k3s.io | sh -
  EOT

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "cluster_token" {
  length = 16
}

output "iid" {
  value = aws_instance.main.id
}

output "public_ip" {
  value = aws_instance.main.public_ip
}

output "cluster_token" {
  value     = random_password.cluster_token.result
  sensitive = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "main" {
  name        = "one-command-cluster-main"
  description = "sg for single node cluster"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "kube-api port from everywhere"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "tag:Name"
    values = ["pub*"]
  }
}

locals {
  pub_subnet = element(data.aws_subnets.public.ids, 0)
}
