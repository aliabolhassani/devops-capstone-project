locals {
  region           = "us-east-1"
  vpc              = "vpc-08b444c062d5e9e82"
  ssh-user         = "ubuntu"
  ami              = "ami-08c40ec9ead489470"
  instance-type    = "t2.micro"
  subnet           = "subnet-0fd348459a0fb6053"
  publicip         = true
  private-key-path = "/home/ali/devops-capstone-project/terraform/ssh-key"
  keyname          = "ssh-key-pair"
  sg-name          = "cp-security-group"
}

resource "tls_private_key" "ssh-key-pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh-key-pair.public_key_openssh
  filename        = "ssh-key.pub"
  file_permission = 600
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh-key-pair.private_key_openssh
  filename        = "ssh-key"
  file_permission = 600
}

resource "aws_security_group" "cp-sg" {
  name        = local.sg-name
  description = local.sg-name
  vpc_id      = local.vpc

  // For HTTP access
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  // For Jenkins access
  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  // For Docker access
  ingress {
    from_port   = 2376
    protocol    = "tcp"
    to_port     = 2376
    cidr_blocks = ["0.0.0.0/0"]
  }

  // For SSH connection
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "cp-key_pair" {
  key_name   = local.keyname
  public_key = tls_private_key.ssh-key-pair.public_key_openssh
}

resource "aws_instance" "cp-vm-instance" {
  ami                         = local.ami
  instance_type               = local.instance-type
  subnet_id                   = local.subnet
  associate_public_ip_address = local.publicip
  key_name                    = local.keyname

  vpc_security_group_ids = [
    aws_security_group.cp-sg.id
  ]

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  tags = {
    Name        = "CP-VM"
    Environment = "TEST"
    OS          = "UBUNTU"
    Managed     = "INFRA"
  }

  depends_on = [aws_security_group.cp-sg]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = local.ssh-user
    private_key = tls_private_key.ssh-key-pair.private_key_openssh
    timeout     = "4m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for SSH connection to be ready...'"
    ]
  }

  provisioner "local-exec" {
    # Export host public_ip as an Ansible inventory file
    command = "echo ${self.public_ip} > host-ips"
  }

  # provisioner "local-exec" {
  #   # Execute the Ansible playbook
  #   command = "ansible-playbook -i hosts-ip --user ${local.ssh-user} --private-key ${local.private-key-path} playbook.yml"
  # }
}

output "ec2instance" {
  value = aws_instance.cp-vm-instance.public_ip
}
