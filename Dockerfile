# --- Stage 1: Build Assets (Tailwind v4) ---
FROM node:20-alpine AS builder
WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./
RUN npm install

# Copy everything else and build
COPY . .
RUN npm run build

# --- Stage 2: Production Server ---
FROM dunglas/frankenphp:1-php8.4-alpine

# Install System dependencies (Required as root)
USER root

# Install dependencies including those for mbstring, xml, and imagick
RUN apk add --no-cache \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    libpq-dev \
    imagemagick-dev \
    ghostscript \
    oniguruma-dev \
    libxml2-dev \
    bash \
    $PHPIZE_DEPS

# Install PHP Extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    pdo_pgsql \
    zip \
    intl \
    opcache \
    bcmath \
    mbstring \
    xml

# Install & Enable Imagick (Fixing potential PECL failures in Alpine)
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set Production Environment
ENV NODE_ENV=production
WORKDIR /app

# Copy Composer files first
COPY composer.json composer.lock ./

# CRITICAL FIX: Added --ignore-platform-reqs to solve the exit code: 2 error
RUN composer install --no-interaction --no-dev --optimize-autoloader --ignore-platform-reqs

# Copy compiled assets from Stage 1
COPY --from=builder /app/web/dist ./web/dist

# Copy application code
COPY . .

# Set permissions for Craft CMS
RUN mkdir -p storage cpresources web/assets \
    && chown -R www-data:www-data storage cpresources web/assets

# Use FrankenPHP's user for security
USER www-data