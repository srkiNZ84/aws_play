#!/bin/bash

SEC_GROUP_NAME=metrics-access
SEC_GROUP_DESCRIPTION="Security group to add ssh, collectd and web access (to be able to see web console)"
UBUNTU_AMI=ami-c135f3aa
KEYPAIR_NAME=metrics-keys
VPC_ID=vpc-4eebfd2b
SUBNET_ID=subnet-b9d0cd83
INSTANCE_TYPE=t2.small
INSTANCE_APPLICATION="Graphite web server"

# Create security group and open ports required
SEC_GROUP_ID=`ec2-add-group $SEC_GROUP_NAME -d "$SEC_GROUP_DESCRIPTION" --vpc $VPC_ID | cut -f 2`
ec2-authorize $SEC_GROUP_ID -p 22 -P tcp
ec2-authorize $SEC_GROUP_ID -p 2003 -P udp
ec2-authorize $SEC_GROUP_ID -p 80 -P tcp
ec2-authorize $SEC_GROUP_ID -p 443 -P tcp

# Create keypair
ec2-create-keypair $KEYPAIR_NAME > $KEYPAIR_NAME.key
chmod 600 $KEYPAIR_NAME.key

# Create instance
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -g $SEC_GROUP_ID -f bootstrap.sh --subnet $SUBNET_ID --associate-public-ip-address true -t $INSTANCE_TYPE | grep INSTANCE | cut -f 2`
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
