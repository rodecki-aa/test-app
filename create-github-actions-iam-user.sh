#!/bin/bash

# Variables
IAM_USER_NAME="github-actions-deployer"
POLICIES=(
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
  "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
)

# 1. Create IAM user
aws iam create-user --user-name $IAM_USER_NAME

# 2. Attach policies
for POLICY_ARN in "${POLICIES[@]}"; do
  aws iam attach-user-policy --user-name $IAM_USER_NAME --policy-arn $POLICY_ARN
done

# 3. Create access keys
ACCESS_KEYS_JSON=$(aws iam create-access-key --user-name $IAM_USER_NAME)
AWS_ACCESS_KEY_ID=$(echo $ACCESS_KEYS_JSON | jq -r '.AccessKey.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo $ACCESS_KEYS_JSON | jq -r '.AccessKey.SecretAccessKey')

echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"

echo "Add these values as GitHub repository secrets for your workflow."
