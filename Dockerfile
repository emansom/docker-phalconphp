FROM php:7.2-fpm
LABEL maintainer="ewout@freedom.nl"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev \
    libcurl4-openssl-dev \
    libpcre3-dev \
    libsodium-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libmcrypt-dev \
    libjpeg-dev \
    openssl \
    libicu-dev \
    && docker-php-ext-install -j$(nproc) mysqli \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) gettext \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && pecl install redis \
    && pecl install apcu \
    && pecl install protobuf \
    && pecl install grpc \
    && pecl install libsodium \
    && docker-php-ext-enable redis apcu protobuf grpc sodium gd mysqli pdo_mysql \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl

ENV PHALCON_VERSION=3.4.0

RUN curl -sSL "https://codeload.github.com/phalcon/cphalcon/tar.gz/v${PHALCON_VERSION}" | tar -xz \
    && cd cphalcon-${PHALCON_VERSION}/build \
    && ./install \
    && cp ../tests/_ci/phalcon.ini $(php-config --configure-options | grep -o "with-config-file-scan-dir=\([^ ]*\)" | awk -F'=' '{print $2}') \
    && cd ../../ \
    && rm -r cphalcon-${PHALCON_VERSION} \
    && docker-php-ext-enable phalcon \
    && mkdir /var/www/html/cache

# TODO: run php-fpm rootless (master too)
# TODO: configure php ini variables like previous Dockerfile
