#!/bin/bash

# Variables
KEY_NAME="bcitkey.pub"
PUBLIC_KEY_PATH="~/.ssh/bcitkey.pub"

# Import the public key into AWS
aws ec2 import-key-pair \
  --key-name "$KEY_NAME" \
  --public-key-material fileb://"$PUBLIC_KEY_PATH" \
  --profile "rylan-sandbox" \
  --region "us-west-2"

if [[ $? -eq 0 ]]; then
  echo "Key pair '$KEY_NAME' imported successfully."
else
  echo "Failed to import key pair."
fi
