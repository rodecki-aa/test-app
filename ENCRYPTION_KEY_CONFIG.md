# ENCRYPTION_KEY Configuration Guide

## Overview
The `ENCRYPTION_KEY` is used to encrypt sensitive data in your Symfony application. It's configured differently for local development and production environments.

## Configuration

### Local Development (.env.local)
For local development, create a `.env.local` file (not committed to git):

```dotenv
ENCRYPTION_KEY=your-local-encryption-key-here
```

### Production (AWS ECS)
For production on AWS, the encryption key is managed through GitHub Actions secrets:

1. **GitHub Secret Configuration**
   - Go to your GitHub repository → Settings → Secrets and variables → Actions
   - Add a secret named `ENCRYPTION_KEY` with your production encryption key value
   - This secret is already referenced in `.github/workflows/deploy.yaml`

2. **GitHub Actions Workflow**
   The workflow automatically passes the secret to CloudFormation:
   ```yaml
   ParameterKey=EncryptionKey,ParameterValue=${{ secrets.ENCRYPTION_KEY }}
   ```

3. **CloudFormation Template**
   The `symfony-ecs.yaml` template:
   - Accepts `EncryptionKey` as a parameter (marked as `NoEcho: true` for security)
   - Passes it as an environment variable to the ECS container
   - The container receives it as `ENCRYPTION_KEY` environment variable

4. **Application Access**
   In your PHP code, access the encryption key via:
   ```php
   $encryptionKey = $_ENV['ENCRYPTION_KEY'] ?? 'fallback-value';
   ```

## Security Best Practices

1. ✅ Never commit `.env.local` to git
2. ✅ Use different encryption keys for dev/staging/prod
3. ✅ The GitHub secret `ENCRYPTION_KEY` should be at least 32 characters
4. ✅ The CloudFormation parameter is marked `NoEcho: true` to hide it from console output
5. ✅ Rotate the encryption key periodically

## Troubleshooting

### Local Development
If you get "Environment variable not found: ENCRYPTION_KEY":
- Create `.env.local` file in your project root
- Add `ENCRYPTION_KEY=your-key-here`

### Production (AWS)
If the application can't find the encryption key:
1. Verify the GitHub secret `ENCRYPTION_KEY` is set
2. Check CloudFormation stack parameters: `aws cloudformation describe-stacks --stack-name symfony-app-stack`
3. Check ECS task definition environment variables
4. View container logs: `aws logs tail /ecs/symfony-app --follow`

## Current Setup

- ✅ `.env` has a default fallback value
- ✅ GitHub Actions workflow passes the secret to CloudFormation
- ✅ CloudFormation passes it to ECS as an environment variable
- ✅ HomeController handles missing encryption key gracefully
- ✅ The key is accessible throughout the application via `$_ENV['ENCRYPTION_KEY']`

