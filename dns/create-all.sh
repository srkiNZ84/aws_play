#!/bin/bash

SEC_GROUP_NAME=bind-servers
SEC_GROUP_DESCRIPTION="Security group to add DNS and SSH access"
UBUNTU_AMI=ami-c135f3aa
KEYPAIR_NAME=dns-server-keys
INSTANCE_APPLICATION="DNS Server (Bind9)"
VPC_ID=vpc-4eebfd2b
SUBNET_ID=subnet-17c5d12d
INSTANCE_TYPE=t2.small
PRIMARY_NETWORK_INTERFACE_DESCRIPTION="Primary DNS server network interface. Associate with public, elastic IP."
PRIMARY_NETWORK_INTERFACE_NAME="Primary DNS server interface"
SECONDARY_NETWORK_INTERFACE_DESCRIPTION="Secondary DNS server network interface. Associate with public, elastic IP."
SECONDARY_NETWORK_INTERFACE_NAME="Secondary DNS server interface"

# Create security group and open ports
SEC_GROUP_ID=`ec2-add-group $SEC_GROUP_NAME -d "$SEC_GROUP_DESCRIPTION" --vpc $VPC_ID | cut -f 2`
ec2-authorize $SEC_GROUP_ID -p 22 -P tcp
ec2-authorize $SEC_GROUP_ID -p 53 -P tcp
ec2-authorize $SEC_GROUP_ID -p 53 -P udp

## Setup elastic addresses and network interfaces
# Allocate and associate the elastic IP's and elastic interfaces
PRIMARY_ELASTIC_IP_ID=`ec2-allocate-address --domain vpc | cut -f 5`
PRIMARY_NETWORK_INTERFACE_ID=`ec2-create-network-interface -d "$PRIMARY_NETWORK_INTERFACE_DESCRIPTION" -g $SEC_GROUP_ID $SUBNET_ID | grep NETWORKINTERFACE | cut -f 2`
ec2-create-tags $PRIMARY_NETWORK_INTERFACE_ID --tag Name="$PRIMARY_NETWORK_INTERFACE_NAME"
ec2-associate-address -a $PRIMARY_ELASTIC_IP_ID -n $PRIMARY_NETWORK_INTERFACE_ID

SECONDARY_ELASTIC_IP_ID=`ec2-allocate-address --domain vpc | cut -f 5`
SECONDARY_NETWORK_INTERFACE_ID=`ec2-create-network-interface -d "$SECONDARY_NETWORK_INTERFACE_DESCRIPTION" -g $SEC_GROUP_ID $SUBNET_ID | grep NETWORKINTERFACE | cut -f 2`
ec2-create-tags $SECONDARY_NETWORK_INTERFACE_ID --tag Name="$SECONDARY_NETWORK_INTERFACE_NAME"
ec2-associate-address -a $SECONDARY_ELASTIC_IP_ID -n $SECONDARY_NETWORK_INTERFACE_ID

# Create keypair
ec2-create-keypair $KEYPAIR_NAME > $KEYPAIR_NAME.key
chmod 600 $KEYPAIR_NAME.key

# Sleep for 10 seconds to ensure that the security group is created before we try to use it for our instances
echo "Sleeping for 10 seconds to ensure our security groups are there when we go to run the instances..."
sleep 10

## Create primary DNS instance
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -f bootstrap.sh -t $INSTANCE_TYPE -a $PRIMARY_NETWORK_INTERFACE_ID:0 | grep INSTANCE | cut -f 2`
echo "Primary DNS Instance id is: $INSTANCE_ID"

# Attach tags
INSTANCE_NAME=`pwgen -A0 -N 1`
ec2-create-tags $INSTANCE_ID --tag Name=$INSTANCE_NAME --tag Application="$INSTANCE_APPLICATION" --tag dns_role=primary

# Get public DNS
PRIMARY_INSTANCE_DNS=`ec2-describe-instances $INSTANCE_ID | grep INSTANCE | cut -f 4`
echo "Primary server DNS set to $PRIMARY_INSTANCE_DNS"


## Create secondary DNS server
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -f bootstrap.sh -t $INSTANCE_TYPE -a $SECONDARY_NETWORK_INTERFACE_ID:0 | grep INSTANCE | cut -f 2`
echo "Secondary DNS Instance id is: $INSTANCE_ID"

# Attach tags
INSTANCE_NAME=`pwgen -A0 -N 1`
ec2-create-tags $INSTANCE_ID --tag Name=$INSTANCE_NAME --tag Application="$INSTANCE_APPLICATION" --tag dns_role=secondary

# Get public DNS
SECONDARY_INSTANCE_DNS=`ec2-describe-instances $INSTANCE_ID | grep INSTANCE | cut -f 4`
echo "Secondary server DNS set to $SECONDARY_INSTANCE_DNS"

# Log in and test
SLEEP=120
echo "Waiting for primary instance to come up, sleeping for $SLEEP seconds..."
sleep $SLEEP
echo "All done waiting, attempting SSH..."
ssh -oStrictHostKeyChecking=no -i $KEYPAIR_NAME.key ubuntu@$PRIMARY_INSTANCE_DNS sudo cat /root/hello_world.txt
echo "Yay!"

echo "Waiting for secondary instance to come up, sleeping for $SLEEP seconds..."
sleep $SLEEP
echo "All done waiting, attempting SSH..."
ssh -oStrictHostKeyChecking=no -i $KEYPAIR_NAME.key ubuntu@$SECONDARY_INSTANCE_DNS sudo cat /root/hello_world.txt
echo "Yay!"
