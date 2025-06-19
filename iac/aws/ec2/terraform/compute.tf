# User Story 1.3: Self-Contained EC2 Instance
# Creates a single EC2 instance with security groups for ERPNext staging environment

# Security group for the EC2 instance
resource "aws_security_group" "erpnext_sg" {
  name_prefix = "${var.project_name}-erpnext-"
  description = "Security group for ERPNext EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH access (port 22)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to specific IPs in production
  }

  # HTTP access (port 80)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access (port 443)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-erpnext-sg"
  }
}

# EC2 instance for ERPNext
resource "aws_instance" "erpnext" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.erpnext_sg.id]
  
  # Associate public IP for internet access
  associate_public_ip_address = true

  # User data script for basic setup
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  # Root volume configuration
  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
    
    tags = {
      Name = "${var.project_name}-erpnext-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-erpnext-instance"
    Type = "application-server"
  }
}
