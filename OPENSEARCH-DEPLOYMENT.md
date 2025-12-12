# OpenSearch Deployment Guide

## Overview
Your CloudFormation template now includes OpenSearch service for indexing and searching car data.

## What's Configured

### OpenSearch Domain
- **Domain Name**: `symfony-app-opensearch`
- **Version**: OpenSearch 2.11
- **Instance Type**: t3.small.search
- **Storage**: 10GB gp3 EBS volume
- **Security**: VPC-based with encryption at rest and node-to-node encryption

### API Endpoints Available

Once deployed, your application will have these endpoints:

1. **Add a car** (POST):
   ```bash
   curl -X POST https://your-alb-url.amazonaws.com/api/cars \
     -H "Content-Type: application/json" \
     -d '{
       "make": "Toyota",
       "model": "Camry",
       "year": 2023,
       "price": 25000,
       "color": "Blue",
       "description": "Well maintained sedan"
     }'
   ```

2. **Search cars** (GET):
   ```bash
   # Get all cars
   curl https://your-alb-url.amazonaws.com/api/cars

   # Search with pagination
   curl "https://your-alb-url.amazonaws.com/api/cars?size=20&from=0"

   # Search by text
   curl "https://your-alb-url.amazonaws.com/api/cars?search=Toyota"
   ```

## Deployment Steps

### 1. Deploy the CloudFormation Stack

```bash
aws cloudformation create-stack \
  --stack-name symfony-app-stack \
  --template-body file://symfony-ecs.yaml \
  --parameters \
    ParameterKey=ImageURI,ParameterValue=605004420352.dkr.ecr.eu-central-1.amazonaws.com/aacars/test:latest \
    ParameterKey=ServiceName,ParameterValue=symfony-app \
    ParameterKey=DBUsername,ParameterValue=vcars \
    ParameterKey=DBPassword,ParameterValue=ChangeMe123! \
    ParameterKey=DBName,ParameterValue=symfony_db \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-central-1
```

### 2. Monitor Deployment Progress

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].StackStatus' \
  --region eu-central-1

# Watch events
aws cloudformation describe-stack-events \
  --stack-name symfony-app-stack \
  --query 'StackEvents[0:10].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId]' \
  --output table \
  --region eu-central-1
```

### 3. Get Your Application URL

```bash
# Get Load Balancer URL
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text \
  --region eu-central-1
```

### 4. Get OpenSearch Endpoint

```bash
# Get OpenSearch endpoint
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`OpenSearchEndpoint`].OutputValue' \
  --output text \
  --region eu-central-1
```

## Resources Created

1. **VPC**: 10.0.0.0/16 with public and private subnets
2. **RDS MySQL**: db.t3.micro instance in private subnets
3. **OpenSearch**: t3.small.search instance in public subnet (VPC-based)
4. **ECS Cluster**: Fargate-based cluster
5. **Application Load Balancer**: Public-facing ALB
6. **Security Groups**: Properly configured for ECS, RDS, ALB, and OpenSearch
7. **IAM Roles**: Task execution and task roles with OpenSearch permissions

## Environment Variables

The ECS task automatically receives these environment variables:

- `APP_ENV=prod`
- `APP_SECRET=ba385594e003b47ad7eb6b2abd76501a`
- `DATABASE_URL=mysql://vcars:password@endpoint:3306/symfony_db`
- `OPENSEARCH_URL=https://opensearch-endpoint`

## Testing the API

### 1. Add Sample Cars

```bash
# Set your ALB URL
ALB_URL="http://your-alb-url.amazonaws.com"

# Add car 1
curl -X POST ${ALB_URL}/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Toyota",
    "model": "Camry",
    "year": 2023,
    "price": 28000,
    "color": "Silver",
    "description": "Reliable family sedan"
  }'

# Add car 2
curl -X POST ${ALB_URL}/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Honda",
    "model": "Civic",
    "year": 2024,
    "price": 24000,
    "color": "Red",
    "description": "Sporty compact car"
  }'

# Add car 3
curl -X POST ${ALB_URL}/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Ford",
    "model": "F-150",
    "year": 2023,
    "price": 45000,
    "color": "Black",
    "description": "Powerful pickup truck"
  }'
```

### 2. Search Cars

```bash
# Get all cars
curl ${ALB_URL}/api/cars

# Search for Toyota
curl "${ALB_URL}/api/cars?search=Toyota"

# Get first 5 cars
curl "${ALB_URL}/api/cars?size=5&from=0"
```

## Troubleshooting

### Check ECS Task Logs

```bash
aws logs tail /ecs/symfony-app --follow --region eu-central-1
```

### Check Service Health

```bash
aws ecs describe-services \
  --cluster symfony-app-cluster \
  --services symfony-app-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Events:events[0:3]}' \
  --region eu-central-1
```

### Check OpenSearch Domain Status

```bash
aws opensearch describe-domain \
  --domain-name symfony-app-opensearch \
  --query 'DomainStatus.{Processing:Processing,Endpoint:Endpoint,Created:Created}' \
  --region eu-central-1
```

## Clean Up

To delete all resources:

```bash
aws cloudformation delete-stack --stack-name symfony-app-stack --region eu-central-1

# Monitor deletion
aws cloudformation wait stack-delete-complete --stack-name symfony-app-stack --region eu-central-1
```

## Notes

- OpenSearch deployment takes approximately 15-20 minutes
- RDS deployment takes approximately 10-15 minutes
- Total stack creation time: ~20-30 minutes
- The OpenSearch domain is in VPC mode for security
- All resources are tagged with the service name for easy identification

