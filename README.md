# Terraform
## Install Terraform
* Use choco package manager
* move the terraform binary file into a suitable directory e.g. C:\terraform
* Add terraform binary file to the path within env variabes

### Secure AWS Keys
* Create Environment Variables for AWS keys

#### Create Folder Strcuture

#### Terraform Script 
* Created terraform scrit to launch an EC2 instance in AWS using our AWS keys which are located in the environment variables
* Terraform can identify the keys and use them to create an EC2 within our AWS account 
* Must ensure we are running terminal as admin in order to provide the neccessary permissions
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

#### 