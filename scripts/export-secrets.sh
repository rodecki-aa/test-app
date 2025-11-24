#!/bin/bash

# Script to export .env file to AWS Secrets Manager
# Usage: ./export-secrets.sh [env-file] [secret-name] [region]

set -e

ENV_FILE="${1:-.env}"
SECRET_NAME="${2:-symfony-app/env}"
AWS_REGION="${3:-eu-central-1}"

echo "Exporting secrets from $ENV_FILE to AWS Secrets Manager..."
echo "Secret Name: $SECRET_NAME"
echo "AWS Region: $AWS_REGION"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found!"
    exit 1
fi

# Read .env file and create JSON object
JSON_STRING="{"
FIRST=true

while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip empty lines and comments
    if [[ -z "$key" ]] || [[ "$key" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    # Remove leading/trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # Skip if key is empty after trimming
    if [[ -z "$key" ]]; then
        continue
    fi

    # Add comma if not first entry
    if [ "$FIRST" = false ]; then
        JSON_STRING+=","
    fi
    FIRST=false

    # Escape special characters in value
    value=$(echo "$value" | sed 's/"/\\"/g')
    JSON_STRING+="\"$key\":\"$value\""
done < "$ENV_FILE"

JSON_STRING+="}"

echo "JSON payload created: $JSON_STRING"

# Check if secret already exists
if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$AWS_REGION" 2>/dev/null; then
    echo "Secret exists. Updating..."
    aws secretsmanager update-secret \
        --secret-id "$SECRET_NAME" \
        --secret-string "$JSON_STRING" \
        --region "$AWS_REGION"
    echo "Secret updated successfully!"
else
    echo "Secret does not exist. Creating..."
    aws secretsmanager create-secret \
        --name "$SECRET_NAME" \
        --description "Symfony application environment variables" \
        --secret-string "$JSON_STRING" \
        --region "$AWS_REGION"
    echo "Secret created successfully!"
fi

# Retrieve and display the secret (for verification)
echo ""
echo "Verifying secret..."
aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --query SecretString \
    --output text \
    --region "$AWS_REGION" | jq .

echo ""
echo "✅ Secrets exported successfully to AWS Secrets Manager!"
echo "Secret ARN:"
aws secretsmanager describe-secret \
    --secret-id "$SECRET_NAME" \
    --query ARN \
    --output text \
    --region "$AWS_REGION"

