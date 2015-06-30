#!/bin/sh

# Delete keypair
ec2-delete-keypair dev-keys

# Delete security group
ec2-delete-group ssh-only
