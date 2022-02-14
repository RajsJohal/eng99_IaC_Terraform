# Terraform
## Install Terraform
* Use choco package manager
* move the terraform binary file into a suitable directory e.g. C:\terraform
* Add terraform binary file to the path within env variabes

### Secure AWS Keys
* Create Environment Variables for AWS keys on localhost machine 

#### Create Folder Strcuture

#### Terraform Script 
* Created terraform script to launch an EC2 instance in AWS using our AWS keys which are located in the environment variables
* Terraform can identify the keys and use them to create an EC2 within our AWS account 
* Must ensure we are running terminal as admin in order to provide the neccessary permissions
* Terrafrom script contains resources which define AWS resources from VPC, subnets, routing tables, security groups and EC2 instances. 
* After script is created:
    - `terraform plan` checks script 
    - `terraform apply` to create instance
    - `terraform destroy` terminates instances mentioned within the script
* Script can be modified to create a new VPC with subnets, and launch the instance within the VPC. Need to edit the security group of instance to ssh into it. 

#### Terrafor Variable file 
* Create a seperate .tf file to store variables which can be used in the main.tf

#### Security Group Rules set up
* Ports 3000, 80 and 22
* ingress for inbound rules 
* egress for outbound rules

#### Creation of VPC, Subnets, Route Tables and deploying instances

##### VPC
```
# Launching a VPC using terraform
resource "aws_vpc" "eng99_raj_vpc" {
    cidr_block = "10.0.0.0/16" # "10.0.0.0/16"
    tags = {
        Name = "eng99_raj_terraform_vpc"
    }
}
```

##### Internet Gateway
```
# Create Internet Gateway
resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.eng99_raj_vpc.id
    tags = {
        Name = "eng99_raj_terraform_IG"
    }
}
```

##### Public Subnet
```
# Create a Public Subnet
resource "aws_subnet" "publicsubnet" {
    vpc_id = aws_vpc.eng99_raj_vpc.id
    cidr_block = "10.0.7.0/24"
    tags = {
      Name = "eng99_raj_terraform_publicSN"
    }
}
```

##### Private Subnet
```
# Private Subnet
resource "aws_subnet" "privatesubnet"{
  vpc_id = aws_vpc.eng99_raj_vpc.id
  cidr_block = "10.0.8.0/24"
  tags = {
    Name = "eng99_raj_terraform_privateSN"
  }
}
```

##### Route Table
```
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
```

```
# Route Table association
resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnet.id
    route_table_id = aws_route_table.PublicRT.id
}
```

##### App Security Group
```
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

```

##### EC2 Instance
```
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
```