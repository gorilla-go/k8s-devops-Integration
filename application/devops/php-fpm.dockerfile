# Use the official PHP 8.0.6 FPM Alpine image as the base image
FROM php:8.0.6-fpm-alpine3.13

# Install dependencies and PHP extensions
RUN apk update && apk add --no-cache \
    freetype-dev \
    jpeg-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    gmp-dev \
    imap-dev \
    icu-dev \
    krb5-dev \
    autoconf \
    g++ \
    make \
    imagemagick-dev \
    gettext-dev \
    && docker-php-ext-install -j$(nproc) bcmath gettext gmp imap intl mysqli pdo_mysql zip opcache \
    && pecl install apcu imagick redis \
    && docker-php-ext-enable apcu imagick redis \
    && apk del autoconf g++ make \
    && rm -rf /var/cache/apk/* /tmp/pear

# copy config
COPY ./php-fpm/php.ini /usr/local/etc/php/php.ini
COPY ./php-fpm/fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html