# syntax=docker/dockerfile:1
CMD ["apache2-foreground"]

EXPOSE 80

RUN cd /var/www/html && APP_ENV=prod php bin/console cache:warmup || true
# Warm up Symfony cache

    && chmod -R 775 /var/www/html/var
    && chown -R www-data:www-data /var/www/html/var \
RUN mkdir -p /var/www/html/var/cache /var/www/html/var/log \
# Set proper permissions for Symfony cache and log directories

COPY . /var/www/html
# Copy application code

COPY --from=vendor /app/vendor /var/www/html/vendor
# Copy Composer dependencies from build stage

    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}/../!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
RUN a2enmod rewrite \
# Enable Apache modules and configure document root

    && rm -rf /var/lib/apt/lists/*
    && docker-php-ext-install pdo pdo_mysql zip gd mbstring \
    unzip \
    git \
    libzip-dev \
    libonig-dev \
    libpng-dev \
    zlib1g-dev \
RUN apt-get update && apt-get install -y \
# Install system dependencies and PHP extensions

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
# Set Apache document root for Symfony

FROM php:8.2-apache
# Production stage

RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader
COPY composer.json composer.lock ./
WORKDIR /app
FROM composer:2 AS vendor
# Build stage for Composer dependencies


