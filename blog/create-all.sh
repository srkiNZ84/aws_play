#!/bin/bash

SEC_GROUP_NAME=http-blog-access
SEC_GROUP_DESCRIPTION="Security group to add http(s) and ssh access"
UBUNTU_AMI=ami-0199636a
KEYPAIR_NAME=blog-keys
INSTANCE_APPLICATION="Wordpress blog"

# Create security group and open port 22
ec2-add-group $SEC_GROUP_NAME -d "$SEC_GROUP_DESCRIPTION"
ec2-authorize $SEC_GROUP_NAME -p 22
ec2-authorize $SEC_GROUP_NAME -p 80
ec2-authorize $SEC_GROUP_NAME -p 443

# Create keypair
ec2-create-keypair $KEYPAIR_NAME > $KEYPAIR_NAME.key
chmod 600 $KEYPAIR_NAME.key

# Create instance
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -g $SEC_GROUP_NAME -f bootstrap.sh | grep INSTANCE | cut -f 2`
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
