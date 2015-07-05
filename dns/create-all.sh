#!/bin/bash

SEC_GROUP_NAME=bind-servers
SEC_GROUP_DESCRIPTION="Security group to add ssh only access"
UBUNTU_AMI=ami-5b748b30
KEYPAIR_NAME=bind-server-keys
INSTANCE_APPLICATION="DNS Server (Bind9)"

# Create security group and open port 22
ec2-add-group $SEC_GROUP_NAME -d "$SEC_GROUP_DESCRIPTION"
ec2-authorize $SEC_GROUP_NAME -p 22
ec2-authorize $SEC_GROUP_NAME -p 53 -P tcp
ec2-authorize $SEC_GROUP_NAME -p 53 -P udp


# Create keypair
ec2-create-keypair $KEYPAIR_NAME > $KEYPAIR_NAME.key
chmod 600 $KEYPAIR_NAME.key


## Create primary DNS instance
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -g $SEC_GROUP_NAME -f bootstrap.sh | grep INSTANCE | cut -f 2`
echo "Primary DNS Instance id is: $INSTANCE_ID"

# Attach tags
INSTANCE_NAME=`pwgen -A0 -N 1`
ec2-create-tags $INSTANCE_ID --tag Name=$INSTANCE_NAME --tag Application="$INSTANCE_APPLICATION" --tag dns_role=primary

# Get public DNS
PRIMARY_INSTANCE_DNS=`ec2-describe-instances $INSTANCE_ID | grep INSTANCE | cut -f 4`
echo "Primary server DNS set to $PRIMARY_INSTANCE_DNS"


## Create secondary DNS instance INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -g $SEC_GROUP_NAME -f bootstrap.sh | grep INSTANCE | cut -f 2` echo "Secondary DNS Instance id is: $INSTANCE_ID"



## Create secondary DNS server
INSTANCE_ID=`ec2run $UBUNTU_AMI -k $KEYPAIR_NAME -g $SEC_GROUP_NAME -f bootstrap.sh | grep INSTANCE | cut -f 2`
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


