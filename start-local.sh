#!/bin/bash

echo "🚀 Starting Symfony application locally..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Stop any running containers
echo "🛑 Stopping any existing containers..."
docker-compose down

# Start the services
echo "🐳 Starting Docker containers..."
docker-compose up -d

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
sleep 10

# Check if vendor directory exists, if not run composer install
if [ ! -d "vendor" ]; then
    echo "📦 Installing PHP dependencies..."
    docker-compose exec app composer install
fi

# Create database if it doesn't exist
echo "🗄️  Setting up database..."
docker-compose exec app php bin/console doctrine:database:create --if-not-exists

# Run migrations or create schema
echo "📋 Creating database schema..."
docker-compose exec app php bin/console doctrine:schema:update --force || true

# Clear cache
echo "🧹 Clearing cache..."
docker-compose exec app php bin/console cache:clear

echo ""
echo "✅ Application is ready!"
echo ""
echo "🌐 Access your application at:"
echo "   - Symfony App: http://localhost:8080"
echo "   - OpenSearch: http://localhost:9200"
echo "   - OpenSearch Dashboards: http://localhost:5601"
echo "   - MySQL: localhost:3306"
echo ""
echo "📊 View logs with: docker-compose logs -f app"
echo "🛑 Stop with: docker-compose down"
echo ""

