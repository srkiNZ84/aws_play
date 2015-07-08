#!/bin/bash

MAIN_VPC_NAME=main-vpc
MAIN_VPC_CIDR=10.0.0.0/16
PUBLIC_SUBNET_CIDR=10.0.0.0/24
PUBLIC_SUBNET_NAME="Public subnet (DMZ)"
PUBLIC_GATEWAY_NAME="Public Internet Gateway"
PUBLIC_ROUTE_TABLE_NAME="Public subnet route table"
INTERNET_CIDR=0.0.0.0/0
MANAGEMENT_SUBNET_CIDR=10.0.1.0/24
MANAGEMENT_SUBNET_NAME="Management subnet"

## Create the main VPC
VPC_ID=`ec2-create-vpc $MAIN_VPC_CIDR | cut -f 2`
echo "VPC ID is: $VPC_ID"
# Name the VPC
ec2-create-tags $VPC_ID --tag Name="$MAIN_VPC_NAME"

## Create and attach the internet gateway
PUBLIC_GATEWAY_ID=`ec2-create-internet-gateway | cut -f 2`
ec2-attach-internet-gateway $PUBLIC_GATEWAY_ID --vpc $VPC_ID
ec2-create-tags $PUBLIC_GATEWAY_ID --tag Name="$PUBLIC_GATEWAY_NAME"

## Create the subnets

# Public Subnet
PUBLIC_SUBNET_ID=`ec2-create-subnet --vpc $VPC_ID --cidr $PUBLIC_SUBNET_CIDR | cut -f 2`
ec2-create-tags $PUBLIC_SUBNET_ID --tag Name="$PUBLIC_SUBNET_NAME"

## Create the route table
# NOTE: by default, when creating a VPC, a route table with rules only for local traffic is created and set as the "Main" (i.e. default) route
# table for all subnets which don't explicitly specify a route table
PUBLIC_ROUTE_TABLE_ID=`ec2-create-route-table $VPC_ID | cut -f 2`
ec2-create-tags $PUBLIC_ROUTE_TABLE_ID --tag Name="$PUBLIC_ROUTE_TABLE_NAME"

# Add rule for routing through the gateway
ec2-create-route $PUBLIC_ROUTE_TABLE_ID --cidr $INTERNET_CIDR --gateway $PUBLIC_GATEWAY_ID

# Associate public route table with the subnet
ec2-associate-route-table $PUBLIC_ROUTE_TABLE_ID --subnet $PUBLIC_SUBNET_ID

# Management Subnet
MANAGEMENT_SUBNET_ID=`ec2-create-subnet --vpc $VPC_ID --cidr $MANAGEMENT_SUBNET_CIDR | cut -f 2`
ec2-create-tags $MANAGEMENT_SUBNET_ID --tag Name="$MANAGEMENT_SUBNET_NAME"

## Configure network ACL's
