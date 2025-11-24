# Symfony AWS Deployment

This repository contains all the necessary files to automatically deploy your Symfony application to AWS ECS using GitHub Actions.

## 📋 Prerequisites

- AWS Account
- GitHub Account
- AWS CLI installed locally
- `jq` installed (for JSON processing)

## 🚀 Setup Instructions

### Step 1: Create GitHub Actions IAM User

Run this script to create an IAM user with the necessary permissions for GitHub Actions:

```bash
./scripts/create-github-user.sh
```

This will output:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Step 2: Add Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add the following secrets:
   - `AWS_ACCESS_KEY_ID` - From the script output
   - `AWS_SECRET_ACCESS_KEY` - From the script output
   - `AWS_REGION` - `eu-central-1` (or your preferred region)
   - `DB_PASSWORD` - Your desired database password (e.g., `ChangeMe123!`)

### Step 3: (Optional) Export Environment Variables to AWS Secrets Manager

If you want to store your `.env` file in AWS Secrets Manager:

```bash
./scripts/export-secrets.sh .env symfony-app/env eu-central-1
```

### Step 4: Push to GitHub

Push your code to the `main` or `master` branch to trigger the deployment:

```bash
git add .
git commit -m "Add AWS deployment configuration"
git push origin main
```

The GitHub Actions workflow will automatically:
1. Build your Docker image
2. Push it to Amazon ECR
3. Create/Update CloudFormation stack
4. Deploy to ECS
5. Output the application URL

## 📦 What Gets Deployed

The CloudFormation stack creates:

- **VPC** with public and private subnets across 2 availability zones
- **Internet Gateway** and routing
- **Security Groups** for ALB, ECS, and RDS
- **Application Load Balancer** for public access
- **ECS Cluster** with Fargate launch type
- **ECS Service** running your Symfony container
- **RDS MySQL 8.0** database in private subnets
- **CloudWatch Log Groups** for container logs
- **IAM Roles** for ECS task execution

## 🔗 Access Your Application

After deployment completes, find your application URL in:

1. **GitHub Actions** output
2. **AWS Console** > CloudFormation > Stacks > `symfony-app-stack` > Outputs
3. Or run:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name symfony-app-stack \
     --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
     --output text
   ```

## 🛠️ Manual Deployment

If you prefer to deploy manually:

```bash
# 1. Create the stack
aws cloudformation create-stack \
  --stack-name symfony-app-stack \
  --template-body file://symfony-ecs.yaml \
  --parameters ParameterKey=DBPassword,ParameterValue=YourPassword123! \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-central-1

# 2. Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name symfony-app-stack \
  --region eu-central-1

# 3. Get the URL
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text
```

## 🗑️ Cleanup

To delete all resources:

```bash
aws cloudformation delete-stack --stack-name symfony-app-stack
```

## 📁 File Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yaml          # GitHub Actions workflow
├── scripts/
│   ├── create-github-user.sh    # Creates IAM user for GitHub Actions
│   └── export-secrets.sh        # Exports .env to Secrets Manager
├── Dockerfile                   # Multi-stage Docker build
├── .dockerignore               # Files to exclude from Docker build
├── symfony-ecs.yaml            # CloudFormation template
└── README-DEPLOYMENT.md        # This file
```

## 🔍 Troubleshooting

### View ECS Task Logs

```bash
aws logs tail /ecs/symfony-app --follow
```

### Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster symfony-app-cluster \
  --services symfony-app-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

### Check Target Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names symfony-app-targets \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
```

### Force New Deployment

```bash
aws ecs update-service \
  --cluster symfony-app-cluster \
  --service symfony-app-service \
  --force-new-deployment
```

## 🔐 Security Notes

- Database is in private subnets (not publicly accessible)
- RDS security group only allows connections from ECS tasks
- Secrets are stored in GitHub Secrets (encrypted)
- IAM roles follow least privilege principle

## 💰 Cost Estimate

Approximate monthly costs (us-east-1):
- ECS Fargate (256 CPU, 512 MB): ~$15/month
- RDS db.t3.micro: ~$15/month
- Application Load Balancer: ~$20/month
- Data transfer: Variable
- **Total: ~$50-60/month**

## 📝 License

This deployment configuration is provided as-is for use with your Symfony application.

