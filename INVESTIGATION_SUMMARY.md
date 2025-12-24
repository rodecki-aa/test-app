# Investigation Summary - 504 Gateway Timeout Issue

## Date: December 24, 2025

## Problem
API endpoints at `/api/cars` and `/api/opensearch/health` are returning 504 Gateway Timeout errors.

## Root Cause
The OPENSEARCH_HOST environment variable in the running container includes `:9200` port suffix:
```
https://vpc-symfony-app-opensearch-rc6igcasdbqdxef6gxlwafktoe.eu-central-1.es.amazonaws.com:9200
```

**AWS OpenSearch VPC endpoints should NOT include the port number.** The correct format is:
```
https://vpc-symfony-app-opensearch-rc6igcasdbqdxef6gxlwafktoe.eu-central-1.es.amazonaws.com
```

## Evidence
1. **Home page working**: Returns HTTP 200, displays environment variables
2. **API endpoints timing out**: `/api/cars` and `/api/opensearch/health` timeout after 30 seconds
3. **Current OPENSEARCH_HOST value**: Includes incorrect `:9200` port (verified via home page output)
4. **ECS service**: Running 1/1 tasks successfully
5. **Health checks**: Passing (HTTP 200 on `/`)

## OpenSearch Configuration Issues
Looking at the CloudFormation template:
- OpenSearch domain is deployed in VPC with security group
- Advanced Security Options: **Disabled** (correct - no auth needed for VPC endpoints)
- The OpenSearchService.php correctly handles VPC endpoints and disables SSL verification
- However, the port :9200 in the URL causes connection issues

## Solution
The CloudFormation template has been updated to remove `:9200` from OPENSEARCH_HOST:

**Before (line 413):**
```yaml
- Name: OPENSEARCH_HOST
  Value: !Sub 'https://${OpenSearchDomain.DomainEndpoint}:9200'
```

**After:**
```yaml
- Name: OPENSEARCH_HOST
  Value: !Sub 'https://${OpenSearchDomain.DomainEndpoint}'
```

## Next Steps
1. Update the CloudFormation stack to deploy the corrected task definition
2. Force new ECS deployment to use updated task definition
3. Verify OpenSearch connectivity via `/api/opensearch/health`
4. Test car creation via `/api/cars` POST endpoint

## Commands to Fix

```bash
# Update the CloudFormation stack
aws cloudformation update-stack \
  --stack-name symfony-app-stack \
  --template-body file://symfony-ecs.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=ImageURI,UsePreviousValue=true \
    ParameterKey=ServiceName,UsePreviousValue=true \
    ParameterKey=DBUsername,UsePreviousValue=true \
    ParameterKey=DBPassword,UsePreviousValue=true \
    ParameterKey=DBName,UsePreviousValue=true \
    ParameterKey=OPENSEARCHUsername,UsePreviousValue=true \
    ParameterKey=OPENSEARCHPassword,UsePreviousValue=true \
    ParameterKey=EncryptionKey,UsePreviousValue=true

# Wait for update to complete
aws cloudformation wait stack-update-complete --stack-name symfony-app-stack

# Force new deployment (if needed)
aws ecs update-service \
  --cluster symfony-app-cluster \
  --service symfony-app-service \
  --force-new-deployment

# Verify the fix
curl http://symfony-app-alb-1910467553.eu-central-1.elb.amazonaws.com/api/opensearch/health
```

## Additional Notes
- The OpenSearchService.php already has proper timeout settings (5s connection, 30s request)
- SSL verification is disabled for AWS VPC endpoints (correct for self-signed certs)
- VPC endpoint detection logic exists to skip auth when using VPC endpoints
- No authentication is configured on the OpenSearch domain (AdvancedSecurityOptions disabled)

