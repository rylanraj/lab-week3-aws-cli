#!/usr/bin/env bash

set -eu

# Variables
region="us-west-2"
vpc_cidr="10.0.0.0/16"
subnet_cidr="10.0.1.0/24"
key_name="bcitkey.pub"
profile="rylan-sandbox"

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --query 'Vpc.VpcId' --output text --region $region --profile $profile)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=MyVPC --region $region --profile $profile

echo "VPC created"
# enable dns hostname
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames Value=true --profile $profile

# Create public subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id \
  --cidr-block $subnet_cidr \
  --availability-zone ${region}a \
  --query 'Subnet.SubnetId' \
  --output text --region $region \
  --profile $profile
)

aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=PublicSubnet --region $region --profile $profile

# Create internet gateway
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
  --output text --region $region --profile $profile)

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $region --profile $profile

# Create route table
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id \
  --query 'RouteTable.RouteTableId' \
  --region $region \
  --output text \
  --profile $profile
)

# Associate route table with public subnet
aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $route_table_id --region $region --profile $profile 

echo "Associated route table with public subnet"

# Create route to the internet via the internet gateway
aws ec2 create-route --route-table-id $route_table_id \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region --profile $profile 

echo "route created"
# Write infrastructure data to a file
echo "vpc_id=${vpc_id}" > infrastructure_data
echo "subnet_id=${subnet_id}" >> infrastructure_data

source ./infrastructure_data

echo "Getting Ubuntu 23.04 image owned by amazon"

# Get Ubuntu 23.04 image id owned by amazon
ubuntu_ami=$(aws ec2 describe-images --region $region \
 --owners amazon \
 --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server* \
 --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text \
 --profile $profile)

echo "Image received"
echo "Creating security group"
# Create security group allowing SSH and HTTP from anywhere
security_group_id=$(aws ec2 create-security-group --group-name MySecurityGroup \
 --description "Allow SSH and HTTP" --vpc-id $vpc_id --query 'GroupId' \
 --region $region \
 --output text \
 --profile $profile
)

aws ec2 authorize-security-group-ingress --group-id $security_group_id \
 --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region --profile $profile 

aws ec2 authorize-security-group-ingress --group-id $security_group_id \
 --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $region --profile $profile

echo "Security group created"
echo "Running instance"
# Launch an EC2 instance in the public subnet
# COMPLETE THIS PART
instance_id=$(aws ec2 run-instances --image-id $ubuntu_ami --count 1 --instance-type t2.micro --key-name $key_name --security-group-ids $security_group_id --subnet-id $subnet_id --associate-public-ip-address --query 'Instances[0].InstanceId' --region $region --output text --profile $profile)

# wait for ec2 instance to be running
aws ec2 wait instance-running --instance-ids $instance_id --region $region --profile $profile

# Get the public IP address of the EC2 instance
# COMPLETE THIS PART
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[*].Instances[*].PublicIpAddress' --region $region --output text --profile $profile )

# Write instance data to a file
# COMPLETE THIS PART
# Define the output file
output_file="ec2_instance_data.txt"

# Write instance details to a file
echo "Instance ID: $instance_id" > $output_file
echo "Public IP: $public_ip" >> $output_file
echo "Region: $region" >> $output_file
echo "Key Name: $key_name" >> $output_file
echo "Security Group ID: $security_group_id" >> $output_file
echo "Subnet ID: $subnet_id" >> $output_file

# Display message
echo "Instance data saved to $output_file"
