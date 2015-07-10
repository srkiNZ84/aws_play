#!/bin/bash

SEC_GROUP_NAME=postfix-server
SEC_GROUP_DESCRIPTION="Security group to add SMTP and SSH access. May include secure, mail related ports in the future (e.g. IMAPS)"
UBUNTU_AMI=ami-c135f3aa
KEYPAIR_NAME=postfix-keys2
INSTANCE_APPLICATION="MTA Server (Postfix)"
VPC_ID=vpc-4eebfd2b
SUBNET_ID=subnet-17c5d12d
INSTANCE_TYPE=m3.medium
MTA_NETWORK_INTERFACE_DESCRIPTION="MTA (mail) network interface, to be used with an elastic IP."
MTA_NETWORK_INTERFACE_NAME="Mail server network interface"

# Create security group and open port 22
SEC_GROUP_ID=`ec2-add-group $SEC_GROUP_NAME -d "$SEC_GROUP_DESCRIPTION" --vpc $VPC_ID | cut -f 2`
ec2-authorize $SEC_GROUP_ID -p 22 -P tcp
ec2-authorize $SEC_GROUP_ID -p 25 -P tcp

## Setup elastic address and network interface
MTA_ELASTIC_IP_ID=`ec2-allocate-address --domain vpc | cut -f 5`
MTA_NETWORK_INTERFACE_ID=`ec2-create-network-interface -d "$MTA_NETWORK_INTERFACE_DESCRIPTION" -g $SEC_GROUP_ID $SUBNET_ID | grep NETWORKINTERFACE | cut -f 2`
ec2-create-tags $MTA_NETWORK_INTERFACE_ID --tag Name="$MTA_NETWORK_INTERFACE_NAME"
ec2-associate-address -a $MTA_ELASTIC_IP_ID -n $MTA_NETWORK_INTERFACE_ID

# Create keypair
ec2-create-keypair $KEYPAIR_NAME > $KEYPAIR_NAME.key
chmod 600 $KEYPAIR_NAME.key

#Sleep for 10 seconds to ensure that the security group is created before we try to ues it for our instance
echo "Sleeping for 10 seconds to ensure that the security group is there when we try to fire up the instance..."
sleep 10

# Create instance
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -f bootstrap.sh -t $INSTANCE_TYPE -a $MTA_NETWORK_INTERFACE_ID:0 | grep INSTANCE | cut -f 2`
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
