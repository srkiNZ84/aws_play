#!/bin/bash

MAIN_VPC_NAME="Main VPC"
MAIN_VPC_CIDR=10.0.0.0/16
PUBLIC_SUBNET_CIDR=10.0.0.0/24
PUBLIC_SUBNET_NAME="Public subnet (DMZ)"
PUBLIC_GATEWAY_NAME="Public Internet Gateway"
PUBLIC_ROUTE_TABLE_NAME="Public subnet route table"
MONITORING_ROUTE_TABLE_NAME="Monitoring subnet route table"
INTERNET_CIDR=0.0.0.0/0
MANAGEMENT_SUBNET_CIDR=10.0.1.0/24
MANAGEMENT_SUBNET_NAME="Management subnet"
MONITORING_SUBNET_CIDR=10.0.2.0/24
MONITORING_SUBNET_NAME="Monitoring subnet"

## Create the main VPC
VPC_ID=`ec2-create-vpc $MAIN_VPC_CIDR | cut -f 2`
echo "VPC ID is: $VPC_ID"
# Name the VPC
ec2-create-tags $VPC_ID --tag Name="$MAIN_VPC_NAME"
# We want DNS please
ec2-modify-vpc-attribute --vpc $VPC_ID --dns-hostnames true

## Create and attach the internet gateway
PUBLIC_GATEWAY_ID=`ec2-create-internet-gateway | cut -f 2`
echo "Gateway ID is: $PUBLIC_GATEWAY_ID"
ec2-attach-internet-gateway $PUBLIC_GATEWAY_ID --vpc $VPC_ID
ec2-create-tags $PUBLIC_GATEWAY_ID --tag Name="$PUBLIC_GATEWAY_NAME"

## Create the subnets

# Public Subnet
PUBLIC_SUBNET_ID=`ec2-create-subnet --vpc $VPC_ID --cidr $PUBLIC_SUBNET_CIDR | cut -f 2`
echo "Public subnet id is: $PUBLIC_SUBNET_ID"
ec2-create-tags $PUBLIC_SUBNET_ID --tag Name="$PUBLIC_SUBNET_NAME"

## Create the route table
# NOTE: by default, when creating a VPC, a route table with rules only for local traffic is created and set as the "Main" (i.e. default) route
# table for all subnets which don't explicitly specify a route table
PUBLIC_ROUTE_TABLE_ID=`ec2-create-route-table $VPC_ID | grep ROUTETABLE | cut -f 2`
echo "Public route table is: $PUBLIC_ROUTE_TABLE_ID"
ec2-create-tags $PUBLIC_ROUTE_TABLE_ID --tag Name="$PUBLIC_ROUTE_TABLE_NAME"

# Add rule for routing through the gateway
ec2-create-route $PUBLIC_ROUTE_TABLE_ID --cidr $INTERNET_CIDR --gateway $PUBLIC_GATEWAY_ID

# Associate public route table with the subnet
ec2-associate-route-table $PUBLIC_ROUTE_TABLE_ID --subnet $PUBLIC_SUBNET_ID

# Management Subnet
MANAGEMENT_SUBNET_ID=`ec2-create-subnet --vpc $VPC_ID --cidr $MANAGEMENT_SUBNET_CIDR | cut -f 2`
echo "Management subnet id is: $MANAGEMENT_SUBNET_ID"
ec2-create-tags $MANAGEMENT_SUBNET_ID --tag Name="$MANAGEMENT_SUBNET_NAME"

# Monitoring Subnet
# NOTE: In future, will not need to associate the internet gateway with the monitoring subnet. This depends on setting up the VPN, so that we can access the machine without going through the internet.
MONITORING_SUBNET_ID=`ec2-create-subnet --vpc $VPC_ID --cidr $MONITORING_SUBNET_CIDR | cut -f 2`
echo "Monitoring subnet id is: $MONITORING_SUBNET_ID"
ec2-create-tags $MONITORING_SUBNET_ID --tag Name="$MONITORING_SUBNET_NAME"

MONITORING_ROUTE_TABLE_ID=`ec2-create-route-table $VPC_ID | grep ROUTETABLE | cut -f 2`
echo "Monitoring route table is: $MONITORING_ROUTE_TABLE_ID"
ec2-create-tags $MONITORING_ROUTE_TABLE_ID --tag Name="$MONITORING_ROUTE_TABLE_NAME"

# Add rule for routing through the gateway
ec2-create-route $MONITORING_ROUTE_TABLE_ID --cidr $INTERNET_CIDR --gateway $PUBLIC_GATEWAY_ID

# Associate monitoring route table with the subnet
ec2-associate-route-table $MONITORING_ROUTE_TABLE_ID --subnet $PUBLIC_SUBNET_ID




## Configure network ACL's
