# Let Terraform kmow who is out cloud provider

# AWS plugins/dependencies will be downloaded
provider "aws" {
    region = var.region # eu-west-1
    # This will allow terraform to create services on eu-west-1


}

# Launching a VPC using terraform
resource "aws_vpc" "eng99_raj_vpc" {
    cidr_block = var.vpc_cidr # "10.0.0.0/16"
    tags = {
        Name = "eng99_raj_terraform_vpc"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.eng99_raj_vpc.id
    tags = {
        Name = "eng99_raj_terraform_IG"
    }
}

# Create a Public Subnet
resource "aws_subnet" "publicsubnet" {
    vpc_id = aws_vpc.eng99_raj_vpc.id
    cidr_block = var.publicSN_CIDR
    tags = {
      Name = var.aws_public_subnet
    }
}

# Create a route table
resource "aws_route_table" "PublicRT" {
    vpc_id = aws_vpc.eng99_raj_vpc.id
         route {
            cidr_block = var.IG_CIDR
            gateway_id = aws_internet_gateway.IGW.id
        }
}

# Route Table association
resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnet.id
    route_table_id = aws_route_table.PublicRT.id
    }

# App EC2 Security Groups
resource "aws_security_group" "allow_tls" {
  name        = "eng99_raj_terraform"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.eng99_raj_vpc.id

  ingress {
    description      = "access the app from anywhere world"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "ssh from world"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
   

# launching an EC2 Instance using Terraform
resource "aws_instance" "app_instance" {
    # add the ami id for 18.04 LTS
    ami = var.app_ami_id

    # choose t2.micro
    instance_type = "t2.micro"

    # Enable public IP for app instance
    associate_public_ip_address = true

    # Subnet selection
    subnet_id = aws_subnet.publicsubnet.id
    
    # Security Group
    vpc_security_group_ids = [aws_security_group.allow_tls.id]

    # add tags for Name
    tags = {
        Name = var.name
    }

    key_name = var.aws_key_name # ensure that we have this key in .ssh folder
}

# To initialise we use terraform init
# terraform plan
# terraform apply

# apply DRY - Do Not Repeat Yourself, create a new terraform file to store variables