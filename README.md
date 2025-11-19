# Automated Deployment Setup

This repository contains an automated deployment pipeline that builds a Docker image from your Symfony application and deploys it to AWS ECS using CloudFormation.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Repository**: `rodecki-aa/test-app.git`
3. **AWS CLI** configured locally (for initial setup)

## Setup Instructions

### 1. Create AWS Secrets Manager Secret

Run the setup script to create your application secrets:

```bash
# Edit the secret values in setup-secrets.sh first
./setup-secrets.sh
```

Or manually create the secret:

```bash
aws secretsmanager create-secret \
  --name symfony-app-secrets \
  --description "Secrets for Symfony application deployment" \
  --secret-string '{
    "DB_PASSWORD": "your-secure-database-password",
    "APP_SECRET": "your-symfony-app-secret-key", 
    "DATABASE_URL": "mysql://username:password@host:3306/database"
  }' \
  --region eu-central-1
```

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository (`Settings` → `Secrets and variables` → `Actions`):

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | `wJalrXUtnFEMI/...` |

### 3. Ensure ECR Repository Exists

Create the ECR repository if it doesn't exist:

```bash
aws ecr create-repository \
  --repository-name aacars/test \
  --region eu-central-1
```

### 4. Deploy Initial Infrastructure (Optional)

You can deploy the infrastructure manually first, or let GitHub Actions do it:

```bash
# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name symfony-app-stack \
  --template-body file://symfony-ecs.yaml \
  --parameters ParameterKey=ImageURI,ParameterValue=605004420352.dkr.ecr.eu-central-1.amazonaws.com/aacars/test:latest \
               ParameterKey=ServiceName,ParameterValue=symfony-app \
  --capabilities CAPABILITY_IAM \
  --region eu-central-1
```

## How the Pipeline Works

### Trigger
- Automatically runs on push to `main` or `master` branch
- Also runs on pull requests for testing

### Pipeline Steps
1. **Checkout**: Gets your code from GitHub
2. **AWS Auth**: Authenticates with AWS using GitHub secrets
3. **Get Secrets**: Retrieves application secrets from AWS Secrets Manager
4. **ECR Login**: Logs into Amazon ECR
5. **Build & Push**: Builds Docker image and pushes to ECR
6. **Deploy Infrastructure**: Updates/creates CloudFormation stack
7. **Update Service**: Forces ECS to deploy new image
8. **Get URL**: Outputs the application URL

### What Gets Created
- VPC with public subnets
- Application Load Balancer (ALB)
- ECS Fargate cluster and service
- Security groups
- IAM roles with appropriate permissions
- CloudWatch log groups

## Accessing Your Application

After deployment, get your application URL:

```bash
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text
```

## Monitoring and Troubleshooting

### Check deployment status
```bash
# CloudFormation stack status
aws cloudformation describe-stacks --stack-name symfony-app-stack

# ECS service status
aws ecs describe-services --cluster symfony-app-cluster --services symfony-app-service

# View container logs
aws logs tail /ecs/symfony-app --follow
```

### Common Issues
1. **ECR Authentication**: Ensure your GitHub secrets are correct
2. **Secrets Manager**: Verify secrets exist and have correct format
3. **ECS Health Check**: Ensure your app responds on port 80 at path "/"

## Updating Application Secrets

To update secrets after initial setup:

```bash
aws secretsmanager update-secret \
  --secret-id symfony-app-secrets \
  --secret-string '{
    "DB_PASSWORD": "new-password",
    "APP_SECRET": "new-app-secret",
    "DATABASE_URL": "mysql://user:pass@host:3306/db"
  }' \
  --region eu-central-1
```

After updating secrets, trigger a new deployment by pushing to your main branch.

## File Structure

```
.
├── .github/workflows/deploy.yml    # GitHub Actions pipeline
├── symfony-ecs.yaml               # CloudFormation template
├── setup-secrets.sh              # Script to create AWS secrets
├── Dockerfile                    # Container definition
└── README.md                    # This file
```

## Security Notes

- Database credentials are stored securely in AWS Secrets Manager
- GitHub only stores AWS access credentials (not application secrets)
- ECS tasks have minimal IAM permissions (only Secrets Manager read access)
- Application runs in private subnets with ALB as public access point
