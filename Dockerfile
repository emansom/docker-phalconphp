FROM php:7.3-rc-fpm
LABEL maintainer="ewout@freedom.nl"

ENV PHALCON_VERSION=3.4.0

RUN curl -sSL "https://codeload.github.com/phalcon/cphalcon/tar.gz/v${PHALCON_VERSION}" | tar -xz \
    && cd cphalcon-${PHALCON_VERSION}/build \
    && ./install \
    && cp ../tests/_ci/phalcon.ini $(php-config --configure-options | grep -o "with-config-file-scan-dir=\([^ ]*\)" | awk -F'=' '{print $2}') \
    && cd ../../ \
    && rm -r cphalcon-${PHALCON_VERSION}

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && pecl install redis \
    && pecl install apcu \
    && pecl install protobuf \
    && pecl install grpc \
    && pecl install libsodium \
    && docker-php-ext-enable redis \
    && docker-php-ext-enable apcu \
    && docker-php-ext-enable protobuf \
    && docker-php-ext-enable grpc \
    && docker-php-ext-enable intl \
    && docker-php-ext-enable libsodium \
    && docker-php-ext-enable sqlite \
    && mkdir -p /var/www/html/{cache,public}
