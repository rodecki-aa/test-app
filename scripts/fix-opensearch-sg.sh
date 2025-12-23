#!/bin/bash
# Script to verify and fix OpenSearch security group rules

set -e

echo "=== Fixing OpenSearch Security Group Rules ==="
echo ""

# Get the security group IDs
echo "1. Finding security groups..."
OPENSEARCH_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=symfony-app-opensearch-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

ECS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=symfony-app-ecs-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "   OpenSearch SG: $OPENSEARCH_SG"
echo "   ECS SG: $ECS_SG"
echo ""

# Check current inbound rules
echo "2. Checking current inbound rules on OpenSearch security group..."
aws ec2 describe-security-groups \
  --group-ids $OPENSEARCH_SG \
  --query 'SecurityGroups[0].IpPermissions' \
  --output json

echo ""
echo "3. Adding/updating inbound rules..."

# Add rule for port 443 (HTTPS) from ECS security group
aws ec2 authorize-security-group-ingress \
  --group-id $OPENSEARCH_SG \
  --protocol tcp \
  --port 443 \
  --source-group $ECS_SG \
  2>/dev/null || echo "   Port 443 rule already exists or error occurred"

# Add rule for port 9200 from ECS security group (backup, though HTTPS uses 443)
aws ec2 authorize-security-group-ingress \
  --group-id $OPENSEARCH_SG \
  --protocol tcp \
  --port 9200 \
  --source-group $ECS_SG \
  2>/dev/null || echo "   Port 9200 rule already exists or error occurred"

echo ""
echo "4. Verifying rules were added..."
aws ec2 describe-security-groups \
  --group-ids $OPENSEARCH_SG \
  --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,UserIdGroupPairs[0].GroupId]' \
  --output table

echo ""
echo "=== Done ==="
echo "If rules were added successfully, wait 30 seconds and test your endpoint again:"
echo "curl http://symfony-app-alb-1665391898.eu-central-1.elb.amazonaws.com/api/opensearch/health"

