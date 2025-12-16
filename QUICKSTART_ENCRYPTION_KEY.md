# Quick Start: Adding ENCRYPTION_KEY to GitHub Secrets

## 1. Generate a Secure Key

```bash
# Generate a random 32-character encryption key
openssl rand -base64 32
```

Example output: `a7B8c9D0e1F2g3H4i5J6k7L8m9N0o1P2q3R4s5T6u7V8=`

## 2. Add to GitHub Secrets

1. Go to: https://github.com/rodecki-aa/test-app/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `ENCRYPTION_KEY`
4. Value: Paste your generated key
5. Click **"Add secret"**

## 3. Deploy

Push to `master` or `main` branch:

```bash
git push origin master
```

The GitHub Actions workflow will automatically:
- Store the key in AWS Secrets Manager
- Configure ECS to inject it into your containers
- Make it available as `$_ENV['ENCRYPTION_KEY']` in PHP

## 4. Use in Your Code

```php
<?php
// In any PHP file
$encryptionKey = $_ENV['ENCRYPTION_KEY'];

// Or in Symfony services
$encryptionKey = $this->getParameter('env(ENCRYPTION_KEY)');
```

## Verification

Check if the secret was created:

```bash
aws secretsmanager describe-secret \
  --secret-id symfony-app/encryption-key \
  --region eu-central-1
```

Check if ECS container has it configured:

```bash
aws ecs describe-task-definition \
  --task-definition symfony-app-task \
  --region eu-central-1 \
  --query 'taskDefinition.containerDefinitions[0].secrets'
```

## That's It! 🎉

Your encryption key is now:
- ✅ Encrypted at rest in AWS Secrets Manager
- ✅ Automatically injected into ECS containers
- ✅ Available as an environment variable
- ✅ Never exposed in logs or task definitions

For more details, see [ENCRYPTION_KEY_SETUP.md](./ENCRYPTION_KEY_SETUP.md)

