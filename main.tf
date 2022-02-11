# Let Terraform kmow who is out cloud provider

# AWS plugins/dependencies will be downloaded
provider "aws" {
    region = "eu-west-1" # eu-west-1
    # This will allow terraform to create services on eu-west-1


}

# Launching a VPC using terraform
resource "aws_vpc" "eng99_raj_vpc" {
    cidr_block = "10.0.0.0/16" # "10.0.0.0/16"
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
    cidr_block = "10.0.7.0/24"
    tags = {
      Name = "eng99_raj_terraform_publicSN"
    }
}

# Private Subnet
resource "aws_subnet" "privatesubnet"{
  vpc_id = aws_vpc.eng99_raj_vpc.id
  cidr_block = "10.0.8.0/24"
  tags = {
    Name = "eng99_raj_terraform_privateSN"
  }
}

# Create a route table
resource "aws_route_table" "PublicRT" {
    vpc_id = aws_vpc.eng99_raj_vpc.id
         route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.IGW.id
        }
    tags = {
      Name = "eng99_raj_terraform_RT"
    }
}

# Private Subnet Routing Table
resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.eng99_raj_vpc.id
  tags = {
    Name = "eng99_raj_terraform_private_RT"
  }
}

# Route Table association
resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnet.id
    route_table_id = aws_route_table.PublicRT.id
}

# Private RT association
resource "aws_route_table_association" "PrivateRTassociation" {
  subnet_id = aws_subnet.privatesubnet.id 
  route_table_id = aws_route_table.PrivateRT.id 
}

# App EC2 Security Groups
resource "aws_security_group" "allow_tls" {
  name        = "eng99_raj_terraform_app_SG"
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

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_security_group" "db_sg" {
  name = "eng99_raj_terraform_db_sg"
  description = "db sg"
  vpc_id = aws_vpc.eng99_raj_vpc.id

  ingress {
    description = "open port 27017"
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "port 22"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.7.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eng99_raj_terraform_dbsg"
  }

}

# Security Group for NAT instance
resource "aws_security_group" "nat_sg" {
  name = "eng99_raj_terraform_nat_sg"
  description = "NAT Security Group"
  vpc_id = aws_vpc.eng99_raj_vpc.id
  
  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  ingress {
    description = "All TCP"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Ping"
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  egress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Ping"
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
   

# launching an app EC2 Instance using Terraform
resource "aws_instance" "app_instance" {
    # add the ami id for 18.04 LTS
    ami = "ami-07d8796a2b0f8d29c"

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

    key_name = "eng99" # ensure that we have this key in .ssh folder
}

# launching db instance using terraform
resource "aws_instance" "db_instance" {
  ami = "ami-07d8796a2b0f8d29c"

  instance_type = "t2.micro"

  associate_public_ip_address = false 

  subnet_id = aws_subnet.publicsubnet.id

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "eng99_raj_terraform_db_instance"
  }

  key_name = "eng99"
}

# NAT Instance
resource "aws_instance" "nat_instance" {
  ami = "ami-00b9ad31459a9dcdf"

  instance_type = "t2.micro"

  associate_public_ip_address = true

  subnet_id = aws_subnet.publicsubnet.id

  vpc_security_group_ids = [aws_security_group.nat_sg.id]

  tags = {
    Name = "eng99_raj_terraform_nat"
  }

  key_name = "eng99"
}

# To initialise we use terraform init
# terraform plan
# terraform apply

# apply DRY - Do Not Repeat Yourself, create a new terraform file to store variables