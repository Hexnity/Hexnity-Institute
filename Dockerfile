# --- Stage 1: Build Assets (Vite/Tailwind) ---
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# --- Stage 2: Production Server ---
FROM dunglas/frankenphp:1-php8.4-alpine

# Install System dependencies for Craft & Imagick
RUN apk add --no-cache \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    libpq-dev \
    imagemagick-dev \
    ghostscript \
    $PHPIZE_DEPS

# Install PHP Extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    pdo_pgsql \
    zip \
    intl \
    opcache

# Install & Enable Imagick
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set Production Environment
ENV NODE_ENV=production
ENV PHP_INI_SCAN_DIR=:/usr/local/etc/php/conf.d
WORKDIR /app

# Copy Composer files first for layer caching
COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Copy compiled assets from Stage 1
COPY --from=builder /app/web/dist ./web/dist

# Copy application code
COPY . .

# Set permissions for Craft
RUN mkdir -p storage cpresources \
    && chown -R www-data:www-data storage cpresources web/assets

# Use FrankenPHP's default entrypoint
USER www-data