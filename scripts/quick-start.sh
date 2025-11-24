#!/bin/bash

# Quick start deployment script
# This script will guide you through the deployment process

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║   Symfony AWS Deployment - Quick Start Script         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    echo "   https://aws.amazon.com/cli/"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Please install it first."
    echo "   Ubuntu/Debian: sudo apt-get install jq"
    echo "   macOS: brew install jq"
    exit 1
fi

echo "✅ Prerequisites satisfied"
echo ""

# Step 1: Create IAM user
echo "════════════════════════════════════════════════════════"
echo "Step 1: Creating IAM User for GitHub Actions"
echo "════════════════════════════════════════════════════════"
echo ""
read -p "Do you want to create a new IAM user for GitHub Actions? (y/n): " CREATE_USER

if [[ "$CREATE_USER" == "y" ]]; then
    ./scripts/create-github-user.sh
    echo ""
    read -p "Press Enter after you've added the secrets to GitHub..."
else
    echo "Skipping IAM user creation..."
fi

echo ""

# Step 2: Export secrets
echo "════════════════════════════════════════════════════════"
echo "Step 2: Export Environment Variables to Secrets Manager"
echo "════════════════════════════════════════════════════════"
echo ""
read -p "Do you want to export .env to AWS Secrets Manager? (y/n): " EXPORT_SECRETS

if [[ "$EXPORT_SECRETS" == "y" ]]; then
    ./scripts/export-secrets.sh
else
    echo "Skipping secrets export..."
fi

echo ""

# Step 3: Manual deployment or GitHub Actions
echo "════════════════════════════════════════════════════════"
echo "Step 3: Choose Deployment Method"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1) Deploy now via AWS CLI (manual)"
echo "2) Push to GitHub and let GitHub Actions deploy"
echo ""
read -p "Enter your choice (1 or 2): " DEPLOY_CHOICE

if [[ "$DEPLOY_CHOICE" == "1" ]]; then
    echo ""
    echo "Starting manual deployment..."

    # Get database password
    read -sp "Enter database password: " DB_PASSWORD
    echo ""

    # Get AWS account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

    # Build and push Docker image
    echo "Building Docker image..."
    docker build -t aacars/test:latest .

    echo "Logging into ECR..."
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com

    echo "Creating ECR repository if not exists..."
    aws ecr create-repository --repository-name aacars/test --region eu-central-1 || true

    echo "Tagging and pushing image..."
    docker tag aacars/test:latest ${ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/aacars/test:latest
    docker push ${ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/aacars/test:latest

    IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/aacars/test:latest"

    echo "Creating CloudFormation stack..."
    aws cloudformation create-stack \
        --stack-name symfony-app-stack \
        --template-body file://symfony-ecs.yaml \
        --parameters \
            ParameterKey=ImageURI,ParameterValue=${IMAGE_URI} \
            ParameterKey=DBPassword,ParameterValue=${DB_PASSWORD} \
        --capabilities CAPABILITY_NAMED_IAM \
        --region eu-central-1

    echo ""
    echo "Stack creation initiated. Waiting for completion..."
    echo "This may take 10-15 minutes..."

    aws cloudformation wait stack-create-complete \
        --stack-name symfony-app-stack \
        --region eu-central-1

    echo ""
    echo "✅ Deployment complete!"

    # Get the URL
    URL=$(aws cloudformation describe-stacks \
        --stack-name symfony-app-stack \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
        --output text \
        --region eu-central-1)

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🎉 Your application is live!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Application URL: $URL"
    echo ""

elif [[ "$DEPLOY_CHOICE" == "2" ]]; then
    echo ""
    echo "To deploy via GitHub Actions:"
    echo ""
    echo "1. Make sure you've added these secrets to GitHub:"
    echo "   - AWS_ACCESS_KEY_ID"
    echo "   - AWS_SECRET_ACCESS_KEY"
    echo "   - AWS_REGION"
    echo "   - DB_PASSWORD"
    echo ""
    echo "2. Push your code to GitHub:"
    echo "   git add ."
    echo "   git commit -m 'Add AWS deployment configuration'"
    echo "   git push origin main"
    echo ""
    echo "3. Check GitHub Actions tab for deployment status"
    echo ""
else
    echo "Invalid choice. Exiting..."
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Setup Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Useful commands:"
echo ""
echo "# View logs"
echo "aws logs tail /ecs/symfony-app --follow"
echo ""
echo "# Check service status"
echo "aws ecs describe-services --cluster symfony-app-cluster --services symfony-app-service"
echo ""
echo "# Force new deployment"
echo "aws ecs update-service --cluster symfony-app-cluster --service symfony-app-service --force-new-deployment"
echo ""
echo "# Delete stack"
echo "aws cloudformation delete-stack --stack-name symfony-app-stack"
echo ""

