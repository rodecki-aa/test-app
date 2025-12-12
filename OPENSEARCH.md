# OpenSearch Integration

This application includes AWS OpenSearch integration for indexing and searching car data.

## Configuration

The OpenSearch URL is automatically configured via the CloudFormation template and passed as an environment variable `OPENSEARCH_URL` to your ECS containers.

For local development, you can override this in `.env.local`:

```dotenv
OPENSEARCH_URL=http://localhost:9200
OPENSEARCH_USERNAME=admin
OPENSEARCH_PASSWORD=admin
```

## API Endpoints

### Health Check
Check OpenSearch connection status:
```bash
curl http://your-app-url/api/opensearch/health
```

### Create Index
Create the cars index in OpenSearch:
```bash
curl -X POST http://your-app-url/api/opensearch/create-index
```

### Add a Car
Add car data to OpenSearch:
```bash
curl -X POST http://your-app-url/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Toyota",
    "model": "Camry",
    "year": 2023,
    "price": 28500.00,
    "color": "Blue",
    "description": "Reliable mid-size sedan with excellent fuel economy"
  }'
```

### Search Cars
Search all cars:
```bash
curl http://your-app-url/api/cars
```

Search with pagination:
```bash
curl "http://your-app-url/api/cars?size=20&from=0"
```

Search with text query:
```bash
curl "http://your-app-url/api/cars?search=Toyota"
```

### Get a Specific Car
```bash
curl http://your-app-url/api/cars/{id}
```

### Delete a Car
```bash
curl -X DELETE http://your-app-url/api/cars/{id}
```

## Example: Bulk Import Sample Cars

```bash
# First, create the index
curl -X POST http://your-app-url/api/opensearch/create-index

# Add sample cars
curl -X POST http://your-app-url/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Honda",
    "model": "Civic",
    "year": 2023,
    "price": 24500.00,
    "color": "Red",
    "description": "Compact car with great reliability"
  }'

curl -X POST http://your-app-url/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Ford",
    "model": "F-150",
    "year": 2023,
    "price": 42500.00,
    "color": "Black",
    "description": "Americas best-selling pickup truck"
  }'

curl -X POST http://your-app-url/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Tesla",
    "model": "Model 3",
    "year": 2023,
    "price": 45000.00,
    "color": "White",
    "description": "Electric sedan with autopilot features"
  }'

curl -X POST http://your-app-url/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "BMW",
    "model": "X5",
    "year": 2023,
    "price": 62500.00,
    "color": "Silver",
    "description": "Luxury midsize SUV with premium features"
  }'

curl -X POST http://your-app-url/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Chevrolet",
    "model": "Malibu",
    "year": 2022,
    "price": 26500.00,
    "color": "Gray",
    "description": "Comfortable sedan with spacious interior"
  }'
```

## Using with AWS Deployed Application

Once your CloudFormation stack is deployed:

1. Get your application URL:
```bash
aws cloudformation describe-stacks \
  --stack-name symfony-app \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text
```

2. Get your OpenSearch endpoint:
```bash
aws cloudformation describe-stacks \
  --stack-name symfony-app \
  --query 'Stacks[0].Outputs[?OutputKey==`OpenSearchURL`].OutputValue' \
  --output text
```

3. Create the index:
```bash
APP_URL=$(aws cloudformation describe-stacks --stack-name symfony-app --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' --output text)
curl -X POST ${APP_URL}/api/opensearch/create-index
```

4. Add sample data:
```bash
curl -X POST ${APP_URL}/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Toyota",
    "model": "Camry",
    "year": 2023,
    "price": 28500.00,
    "color": "Blue",
    "description": "Reliable mid-size sedan"
  }'
```

## Local Development with OpenSearch

Run OpenSearch locally using Docker:

```bash
docker run -d \
  --name opensearch \
  -p 9200:9200 \
  -p 9600:9600 \
  -e "discovery.type=single-node" \
  -e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=Admin123!" \
  -e "plugins.security.disabled=true" \
  opensearchproject/opensearch:2.11.0
```

Then update your `.env.local`:
```dotenv
OPENSEARCH_URL=http://localhost:9200
OPENSEARCH_USERNAME=
OPENSEARCH_PASSWORD=
```

## Troubleshooting

### Check OpenSearch is accessible from ECS
```bash
# Get task ARN
TASK_ARN=$(aws ecs list-tasks --cluster symfony-app-cluster --query 'taskArns[0]' --output text)

# Check task logs
aws logs tail /ecs/symfony-app --follow
```

### Test OpenSearch endpoint directly
The OpenSearch domain is in a VPC and only accessible from ECS tasks. Use the API endpoints to interact with it.

