#!/bin/bash

# Setup AWS Secrets Manager for Symfony Application
# This script creates the necessary secrets for your Symfony app deployment

AWS_REGION="eu-central-1"
SECRET_NAME="symfony-app-secrets"

echo "Setting up AWS Secrets Manager for Symfony application..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Prompt for secret values
read -p "Enter database password: " -s DB_PASSWORD
echo
read -p "Enter Symfony APP_SECRET: " -s APP_SECRET
echo
read -p "Enter complete DATABASE_URL (mysql://user:pass@host:3306/dbname): " DATABASE_URL

# Create the secret JSON
SECRET_JSON=$(cat <<EOF
{
  "DB_PASSWORD": "$DB_PASSWORD",
  "APP_SECRET": "$APP_SECRET",
  "DATABASE_URL": "$DATABASE_URL"
}
EOF
)

# Create or update the secret
if aws secretsmanager describe-secret --secret-id $SECRET_NAME --region $AWS_REGION > /dev/null 2>&1; then
    echo "Secret exists, updating..."
    aws secretsmanager update-secret \
        --secret-id $SECRET_NAME \
        --secret-string "$SECRET_JSON" \
        --region $AWS_REGION
    echo "Secret updated successfully!"
else
    echo "Creating new secret..."
    aws secretsmanager create-secret \
        --name $SECRET_NAME \
        --description "Secrets for Symfony application deployment" \
        --secret-string "$SECRET_JSON" \
        --region $AWS_REGION
    echo "Secret created successfully!"
fi

echo "You can now deploy your application using the GitHub Actions pipeline."
echo "Make sure to set the following GitHub secrets:"
echo "- AWS_ACCESS_KEY_ID"
echo "- AWS_SECRET_ACCESS_KEY"

# Example commands for manual testing (commented out for security)
echo ""
echo "To verify the secrets were created, run:"
echo "aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $AWS_REGION --query SecretString --output text"
