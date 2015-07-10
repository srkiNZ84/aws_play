#!/bin/bash

SEC_GROUP_NAME=http-blog-access
SEC_GROUP_DESCRIPTION="Security group to add http(s) and ssh access"
UBUNTU_AMI=ami-c135f3aa
KEYPAIR_NAME=blog-keys2
INSTANCE_APPLICATION="Wordpress blog"
VPC_ID=vpc-4eebfd2b
SUBNET_ID=subnet-17c5d12d
INSTANCE_TYPE=t2.small
BLOG_INTERFACE_DESCRIPTION="Blog or other public network interface. To be used for the 'main' site"
BLOG_INTERFACE_NAME="Blog (Wordpress) network interface"

# Create security group and open port 22
SEC_GROUP_ID=`ec2-add-group $SEC_GROUP_NAME -d "$SEC_GROUP_DESCRIPTION" --vpc $VPC_ID | cut -f 2`
ec2-authorize $SEC_GROUP_ID -p 22 -P tcp
ec2-authorize $SEC_GROUP_ID -p 80 -P tcp
ec2-authorize $SEC_GROUP_ID -p 443 -P tcp

## Setup elastic address and network interface
BLOG_ELASTIC_IP_ID=`ec2-allocate-address --domain vpc | cut -f 5`
BLOG_NETWORK_INTERFACE_ID=`ec2-create-network-interface -d "$BLOG_NETWORK_INTERFACE_DESCRIPTION" -g $SEC_GROUP_ID $SUBNET_ID | grep NETWORKINTERFACE | cut -f 2`
ec2-create-tags $BLOG_NETWORK_INTERFACE_ID --tag Name="$BLOG_INTERFACE_NAME"
ec2-associate-address -a $BLOG_ELASTIC_IP_ID -n $BLOG_NETWORK_INTERFACE_ID

# Create keypair
ec2-create-keypair $KEYPAIR_NAME > $KEYPAIR_NAME.key
chmod 600 $KEYPAIR_NAME.key

echo "Sleeping for 10...."
sleep 10

# Create instance
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -f bootstrap.sh -t $INSTANCE_TYPE -a $BLOG_NETWORK_INTERFACE_ID:0 | grep INSTANCE | cut -f 2`
echo "Instance id is: $INSTANCE_ID"

# Attach tags
INSTANCE_NAME=`pwgen -A0 -N 1`
ec2-create-tags $INSTANCE_ID --tag Name=$INSTANCE_NAME --tag Application="$INSTANCE_APPLICATION"

# Get public DNS
INSTANCE_DNS=`ec2-describe-instances $INSTANCE_ID | grep INSTANCE | cut -f 4`
echo "DNS set to $INSTANCE_DNS"

# Log in and test
SLEEP=120
echo "Waiting for instance to come up, sleeping for $SLEEP seconds..."
sleep $SLEEP
echo "All done waiting, attempting SSH..."
ssh -oStrictHostKeyChecking=no -i $KEYPAIR_NAME.key ubuntu@$INSTANCE_DNS sudo cat /root/hello_world.txt
echo "Yay!"
