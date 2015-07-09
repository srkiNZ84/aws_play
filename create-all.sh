#!/bin/bash

SEC_GROUP_NAME=ssh-only
SEC_GROUP_DESCRIPTION="Security group to add ssh only access"
UBUNTU_AMI=ami-0199636a
KEYPAIR_NAME=dev-keys
VPC_ID=
SUBNET_ID=
INSTANCE_TYPE=m3.medium

# Create security group and open port 22
SEC_GROUP_ID=`ec2-add-group $SEC_GROUP_NAME -d "$SEC_GROUP_DESCRIPTION" --vpc $VPC_ID | cut -f 2`
ec2-authorize $SEC_GROUP_ID -p 22 -P tcp

# Create keypair
ec2-create-keypair $KEYPAIR_NAME > $KEYPAIR_NAME.key
chmod 600 $KEYPAIR_NAME.key

# Create instance
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -g $SEC_GROUP_ID -f bootstrap.sh --subnet $SUBNET_ID --associate-public-ip-address true -t $INSTANCE_TYPE | grep INSTANCE | cut -f 2`
echo "Instance id is: $INSTANCE_ID"

# Attach tags
ec2-create-tags $INSTANCE_ID --tag Name=first --tag Application=test

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
