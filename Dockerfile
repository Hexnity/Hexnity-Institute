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

# 1. Setup Caddy/FrankenPHP system directories (Fixes the permission denied crash)
RUN mkdir -p /data/caddy /config/caddy \
    && chown -R www-data:www-data /data /config

# 2. Handle Composer
COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-dev --optimize-autoloader --ignore-platform-reqs

# 3. Copy application code and assets
COPY . .
COPY --from=builder /app/web/dist ./web/dist

# 4. RUTHLESS PATH CLEANUP
# Remove the 'public' folder so it cannot hijack requests meant for 'web'
RUN rm -rf /app/public

# 5. HARDCODE WEB ROOT
# This forces FrankenPHP to serve from /app/web and prevents the phpinfo() issue
RUN echo ':80 { \n\
    root * /app/web \n\
    php_server \n\
    file_server \n\
}' > /etc/frankenphp/Caddyfile

# 6. Final Permissions for Craft CMS
RUN mkdir -p storage cpresources web/assets \
    && chown -R www-data:www-data /app storage cpresources web/assets /etc/frankenphp/Caddyfile

# Use FrankenPHP's user for security
USER www-data

# Ensure the server knows to listen on port 80
ENV SERVER_NAME=:80