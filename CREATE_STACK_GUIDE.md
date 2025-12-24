# How to Create CloudFormation Stack for Symfony Application

## Prerequisites
- AWS CLI installed and configured
- `symfony-ecs.yaml` CloudFormation template file
- Docker image pushed to ECR: `605004420352.dkr.ecr.eu-central-1.amazonaws.com/aacars/test:latest`

## Step 1: Create the Stack

```bash
aws cloudformation create-stack \
  --stack-name symfony-app-stack \
  --template-body file:///home/tomasz/projects/test-cloud-app/symfony-ecs.yaml \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=DBPassword,ParameterValue=ChangeMe123! \
    ParameterKey=EncryptionKey,ParameterValue=wpcEcBeBhEhpM3Cx2d9+d3X3rrK7M2euwNzNeci8iMs \
  --region eu-central-1
```

### Parameters Explained:
- `--stack-name`: Name of your CloudFormation stack
- `--template-body`: Path to your CloudFormation template
- `--capabilities`: Required for creating IAM roles
- `--parameters`: 
  - `DBPassword`: MySQL database password (change in production!)
  - `EncryptionKey`: Key for encrypting sensitive data

### Other Parameters (using defaults):
- `ImageURI`: Default is `605004420352.dkr.ecr.eu-central-1.amazonaws.com/aacars/test:latest`
- `ServiceName`: Default is `symfony-app`
- `DBUsername`: Default is `vcars`
- `DBName`: Default is `symfony_db`
- `OPENSEARCHUsername`: Default is `admin`
- `OPENSEARCHPassword`: Default is `admin`

## Step 2: Monitor Stack Creation

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].StackStatus' \
  --output text

# Watch stack events in real-time
aws cloudformation describe-stack-events \
  --stack-name symfony-app-stack \
  --query 'StackEvents[0:10].[Timestamp,ResourceType,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table
```

## Step 3: Wait for Stack Creation (10-15 minutes)

```bash
# Wait for stack to complete (blocking command)
aws cloudformation wait stack-create-complete --stack-name symfony-app-stack
echo "Stack created successfully!"
```

## Step 4: Get Application URL and Endpoints

```bash
# Get all outputs (Load Balancer URL, OpenSearch endpoint, etc.)
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].Outputs' \
  --output table

# Get just the Load Balancer URL
aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text
```

## Step 5: Verify Application is Running

```bash
# Get the Load Balancer URL
LB_URL=$(aws cloudformation describe-stacks \
  --stack-name symfony-app-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text)

# Test home page
curl -s $LB_URL

# Test API health endpoint
curl -s $LB_URL/api/health | jq '.'

# Test OpenSearch health
curl -s $LB_URL/api/opensearch/health | jq '.'
```

## What Gets Created

The CloudFormation stack creates:

### Networking:
- VPC with public and private subnets (2 AZs)
- Internet Gateway
- Route tables
- Security groups for ALB, ECS, RDS, and OpenSearch

### Compute:
- ECS Cluster
- ECS Task Definition (Fargate)
- ECS Service with auto-scaling
- Application Load Balancer
- Target Group

### Data:
- RDS MySQL database (db.t3.micro)
- OpenSearch domain (t3.small.search)

### Security:
- IAM roles for ECS task execution
- Secrets Manager for encryption key
- Security groups with proper access controls

## Update Existing Stack

If the stack already exists and you want to update it:

```bash
aws cloudformation update-stack \
  --stack-name symfony-app-stack \
  --template-body file:///home/tomasz/projects/test-cloud-app/symfony-ecs.yaml \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ImageURI,UsePreviousValue=true \
    ParameterKey=ServiceName,UsePreviousValue=true \
    ParameterKey=DBUsername,UsePreviousValue=true \
    ParameterKey=DBPassword,UsePreviousValue=true \
    ParameterKey=DBName,UsePreviousValue=true \
    ParameterKey=OPENSEARCHUsername,UsePreviousValue=true \
    ParameterKey=OPENSEARCHPassword,UsePreviousValue=true \
    ParameterKey=EncryptionKey,UsePreviousValue=true
```

## Delete Stack

To delete all resources:

```bash
aws cloudformation delete-stack --stack-name symfony-app-stack

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name symfony-app-stack
```

## Troubleshooting

### Stack Creation Failed

```bash
# Check which resource failed
aws cloudformation describe-stack-events \
  --stack-name symfony-app-stack \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table
```

### Application Not Responding

```bash
# Check ECS service
aws ecs describe-services \
  --cluster symfony-app-cluster \
  --services symfony-app-service

# Check container logs
aws logs tail /ecs/symfony-app --follow
```

### OpenSearch Connection Issues

The **OPENSEARCH_HOST should NOT include port :9200** for AWS OpenSearch VPC endpoints.

Correct format: `https://vpc-domain-name.region.es.amazonaws.com`
Wrong format: `https://vpc-domain-name.region.es.amazonaws.com:9200`

## Important Notes

1. **Cost**: Running this stack costs approximately $50-100/month depending on usage
2. **Database Password**: Change `ChangeMe123!` to a secure password
3. **Encryption Key**: Generate a secure encryption key for production
4. **Region**: Default is `eu-central-1`, change if needed
5. **Scaling**: Current setup uses 1 ECS task, adjust `DesiredCount` for production

## GitHub Actions Integration

The stack is automatically deployed when you push to the `master` branch using GitHub Actions workflow defined in `.github/workflows/deploy.yml`.

Required GitHub Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ENCRYPTION_KEY`

