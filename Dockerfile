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

# Install & Enable Imagick
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set Production Environment
ENV NODE_ENV=production
WORKDIR /app

# 1. Setup Caddy/FrankenPHP system directories (Essential fix for the crash)
RUN mkdir -p /data/caddy /config/caddy \
    && chown -R www-data:www-data /data /config

# 2. Handle Composer
COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-dev --optimize-autoloader --ignore-platform-reqs

# 3. Copy Assets and Code
COPY --from=builder /app/web/dist ./web/dist
COPY . .

# 4. Final Permissions for Craft CMS folders
RUN mkdir -p storage cpresources web/assets \
    && chown -R www-data:www-data /app storage cpresources web/assets

# Use FrankenPHP's user for security
USER www-data