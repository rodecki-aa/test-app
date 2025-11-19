#!/bin/bash

# Deployment validation script
# Run this script to verify your deployment setup is correct

echo "🔍 Validating deployment setup..."
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not installed"
    exit 1
else
    echo "✅ AWS CLI installed"
fi

# Check AWS credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured"
    exit 1
else
    echo "✅ AWS credentials configured"
fi

# Check if ECR repository exists
AWS_REGION="eu-central-1"
ECR_REPO="aacars/test"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION > /dev/null 2>&1; then
    echo "✅ ECR repository exists: $ECR_REPO"
else
    echo "⚠️  ECR repository does not exist. Creating..."
    aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION
    echo "✅ ECR repository created: $ECR_REPO"
fi

# Check if secrets exist
SECRET_NAME="symfony-app-secrets"
if aws secretsmanager describe-secret --secret-id $SECRET_NAME --region $AWS_REGION > /dev/null 2>&1; then
    echo "✅ AWS Secrets Manager secret exists: $SECRET_NAME"
else
    echo "❌ AWS Secrets Manager secret does not exist"
    echo "   Run ./setup-secrets.sh to create it"
    exit 1
fi

# Check required files
FILES=(
    "Dockerfile"
    "composer.json"
    ".github/workflows/deploy.yml"
    "symfony-ecs.yaml"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ Required file exists: $file"
    else
        echo "❌ Required file missing: $file"
        exit 1
    fi
done

# Validate CloudFormation template
echo "🔍 Validating CloudFormation template..."
if aws cloudformation validate-template --template-body file://symfony-ecs.yaml > /dev/null 2>&1; then
    echo "✅ CloudFormation template is valid"
else
    echo "❌ CloudFormation template validation failed"
    aws cloudformation validate-template --template-body file://symfony-ecs.yaml
    exit 1
fi

echo ""
echo "🎉 All checks passed! Your deployment setup is ready."
echo ""
echo "Next steps:"
echo "1. Ensure your GitHub repository has these secrets configured:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo "2. Push your code to the main/master branch to trigger deployment"
echo ""
echo "3. Monitor the deployment in GitHub Actions"
echo ""
echo "4. After deployment, get your app URL with:"
echo "   aws cloudformation describe-stacks --stack-name symfony-app-stack --query 'Stacks[0].Outputs[?OutputKey==\`LoadBalancerURL\`].OutputValue' --output text"
