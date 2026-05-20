FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM dunglas/frankenphp:1-php8.4-alpine

USER root

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

RUN pecl install imagick \
    && docker-php-ext-enable imagick

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ENV NODE_ENV=production
WORKDIR /app

RUN mkdir -p /data/caddy /config/caddy \
    && chown -R www-data:www-data /data /config

COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-dev --optimize-autoloader --ignore-platform-reqs

COPY . .
COPY --from=builder /app/web/dist ./web/dist

RUN rm -rf /app/public

RUN printf ":80\nroot * /app/web\nphp_server\nfile_server" > /etc/frankenphp/Caddyfile

RUN mkdir -p storage cpresources web/assets \
    && chown -R www-data:www-data /app /etc/frankenphp/Caddyfile

USER www-data
ENV SERVER_NAME=:80