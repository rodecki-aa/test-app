#!/bin/bash

# This script demonstrates how to add sample car data to OpenSearch using the API

# Set your application URL (replace with your actual URL)
APP_URL="http://localhost:8000"

# If deployed on AWS, get the URL from CloudFormation:
# APP_URL=$(aws cloudformation describe-stacks --stack-name symfony-app --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' --output text)

echo "Using APP_URL: $APP_URL"
echo ""

# Step 1: Create the OpenSearch index
echo "1. Creating OpenSearch index..."
curl -X POST "${APP_URL}/api/opensearch/create-index"
echo -e "\n"

# Step 2: Check OpenSearch health
echo "2. Checking OpenSearch health..."
curl "${APP_URL}/api/opensearch/health"
echo -e "\n"

# Step 3: Add sample cars
echo "3. Adding sample cars..."

echo "Adding Toyota Camry..."
curl -X POST "${APP_URL}/api/cars" \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Toyota",
    "model": "Camry",
    "year": 2023,
    "price": 28500.00,
    "color": "Blue",
    "description": "Reliable mid-size sedan with excellent fuel economy"
  }'
echo -e "\n"

echo "Adding Honda Civic..."
curl -X POST "${APP_URL}/api/cars" \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Honda",
    "model": "Civic",
    "year": 2023,
    "price": 24500.00,
    "color": "Red",
    "description": "Compact car with great reliability"
  }'
echo -e "\n"

echo "Adding Ford F-150..."
curl -X POST "${APP_URL}/api/cars" \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Ford",
    "model": "F-150",
    "year": 2023,
    "price": 42500.00,
    "color": "Black",
    "description": "Americas best-selling pickup truck"
  }'
echo -e "\n"

echo "Adding Tesla Model 3..."
curl -X POST "${APP_URL}/api/cars" \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Tesla",
    "model": "Model 3",
    "year": 2023,
    "price": 45000.00,
    "color": "White",
    "description": "Electric sedan with autopilot features"
  }'
echo -e "\n"

echo "Adding BMW X5..."
curl -X POST "${APP_URL}/api/cars" \
  -H "Content-Type: application/json" \
  -d '{
    "make": "BMW",
    "model": "X5",
    "year": 2023,
    "price": 62500.00,
    "color": "Silver",
    "description": "Luxury midsize SUV with premium features"
  }'
echo -e "\n"

# Step 4: Search all cars
echo "4. Searching all cars..."
curl "${APP_URL}/api/cars"
echo -e "\n"

# Step 5: Search for specific make
echo "5. Searching for Toyota..."
curl "${APP_URL}/api/cars?search=Toyota"
echo -e "\n"

echo "Done!"

