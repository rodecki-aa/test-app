# Encryption Key Setup Guide

This guide explains how to configure and use the `ENCRYPTION_KEY` environment variable in your ECS containers.

## Overview

The `ENCRYPTION_KEY` is securely stored in **AWS Secrets Manager** and automatically injected into your ECS containers at runtime. This is the recommended best practice for handling sensitive configuration data.

## Setup Steps

### 1. Add the Secret to GitHub

Add the `ENCRYPTION_KEY` to your GitHub repository secrets:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `ENCRYPTION_KEY`
5. Value: Your encryption key (minimum 16 characters, recommended 32+ characters)
6. Click **Add secret**

**Example encryption key generation:**
```bash
# Generate a secure 32-character encryption key
openssl rand -base64 32
```

### 2. Deploy Your Application

When you push to `main` or `master` branch, the GitHub Actions workflow will:
1. Create a Secrets Manager secret with your encryption key
2. Configure ECS to inject it as `ENCRYPTION_KEY` environment variable
3. Deploy your application

### 3. Access in Your Application

The `ENCRYPTION_KEY` is available as a standard environment variable in your container:

**PHP Example:**
```php
$encryptionKey = $_ENV['ENCRYPTION_KEY'] ?? '';

// Or using Symfony
$encryptionKey = $this->getParameter('env(ENCRYPTION_KEY)');
```

**In your `.env` file (for reference only, actual value comes from Secrets Manager):**
```env
# This is just documentation - actual value comes from AWS Secrets Manager
ENCRYPTION_KEY=your-encryption-key-here
```

## Architecture

### How It Works

```
GitHub Secret (ENCRYPTION_KEY)
    ↓
CloudFormation Parameter
    ↓
AWS Secrets Manager Secret
    ↓
ECS Task Definition (Secrets section)
    ↓
Container Environment Variable (ENCRYPTION_KEY)
```

### Security Benefits

1. **Encrypted at Rest**: Secrets Manager encrypts data using AWS KMS
2. **Encrypted in Transit**: Secure connection between ECS and Secrets Manager
3. **Access Control**: IAM roles control who/what can access the secret
4. **Audit Trail**: CloudTrail logs all secret access
5. **No Plain Text**: Never stored in plain text in task definitions or logs

## CloudFormation Details

### Resources Created

- **Secret**: `symfony-app/encryption-key` in AWS Secrets Manager
- **IAM Policy**: TaskExecutionRole has permission to read the secret
- **ECS Integration**: Secret is injected via the `Secrets` section (not `Environment`)

### Manual Deployment

If deploying manually via AWS CLI:

```bash
aws cloudformation create-stack \
  --stack-name symfony-app-stack \
  --template-body file://symfony-ecs.yaml \
  --parameters \
    ParameterKey=EncryptionKey,ParameterValue="your-secure-key-here" \
    ParameterKey=DBPassword,ParameterValue="your-db-password" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-central-1
```

## Updating the Encryption Key

### Method 1: Via CloudFormation Update

```bash
aws cloudformation update-stack \
  --stack-name symfony-app-stack \
  --use-previous-template \
  --parameters \
    ParameterKey=EncryptionKey,ParameterValue="new-encryption-key" \
    ParameterKey=DBPassword,UsePreviousValue=true \
    ParameterKey=DBUsername,UsePreviousValue=true \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-central-1
```

### Method 2: Directly Update Secrets Manager

```bash
# Update the secret value
aws secretsmanager update-secret \
  --secret-id symfony-app/encryption-key \
  --secret-string "new-encryption-key" \
  --region eu-central-1

# Force ECS to redeploy with new secret
aws ecs update-service \
  --cluster symfony-app-cluster \
  --service symfony-app-service \
  --force-new-deployment \
  --region eu-central-1
```

## Troubleshooting

### Check if Secret Exists

```bash
aws secretsmanager describe-secret \
  --secret-id symfony-app/encryption-key \
  --region eu-central-1
```

### View Secret Value (requires permissions)

```bash
aws secretsmanager get-secret-value \
  --secret-id symfony-app/encryption-key \
  --region eu-central-1 \
  --query SecretString \
  --output text
```

### Check ECS Task Has Access

```bash
# View task definition
aws ecs describe-task-definition \
  --task-definition symfony-app-task \
  --region eu-central-1 \
  --query 'taskDefinition.containerDefinitions[0].secrets'
```

### Common Issues

1. **"AccessDeniedException"**: TaskExecutionRole lacks permissions
   - Check IAM policy includes `secretsmanager:GetSecretValue`

2. **Secret not found**: Check secret name matches exactly
   - Secret name: `symfony-app/encryption-key`

3. **Container can't access variable**: 
   - Verify secret is in `secrets` section, not `environment`
   - Check CloudWatch logs for startup errors

## Best Practices

1. **Rotate Regularly**: Update encryption key periodically
2. **Use Strong Keys**: Minimum 32 characters, random generation
3. **Limit Access**: Only grant necessary IAM permissions
4. **Monitor Usage**: Enable CloudTrail logging for secret access
5. **Separate Environments**: Use different keys for dev/staging/prod

## Related Resources

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [ECS Secrets Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data-secrets.html)
- [Symfony Secrets Management](https://symfony.com/doc/current/configuration/secrets.html)

## Summary

✅ **Secure**: Stored in AWS Secrets Manager with encryption  
✅ **Automatic**: Injected by ECS at container startup  
✅ **Versioned**: Can be updated without code changes  
✅ **Auditable**: All access logged via CloudTrail  
✅ **Simple**: Accessed as standard environment variable  

