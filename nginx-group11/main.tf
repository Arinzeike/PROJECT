# Define a security group to allow HTTP and SSH traffic
resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow HTTP traffic on port 80 and SSH on port 22"
  vpc_id      = var.vpc_id  

  # Ingress rule for HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  # Ingress rule for SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  # Egress rule (allow all outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define an EC2 instance
resource "aws_instance" "nginx_server" {
  ami           = var.ami_id  
  instance_type = "t2.medium"
  key_name      = var.key_name  

  # Attach the security group to the EC2 instance
  security_groups = [aws_security_group.allow_http_ssh.name]

  # User data script to install and start Nginx using apt
  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x
    sudo apt update -y
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
  EOF

  # Tagging the EC2 instance
  tags = {
    Name = var.instance_name  
  }
}

