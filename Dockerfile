FROM php:7.2-fpm-alpine
LABEL maintainer="ewout@freedom.nl"

# Install shared libraries needed by several dependencies of Phalcon
RUN set -xe; \
    \
    apk add --no-cache --virtual .phalcon-persistent-deps \
         pcre-dev \
         icu-dev \
         libintl \
         gettext-dev

# Install, compile and configure all dependencies for Phalcon
RUN set -xe; \
    \
    apk add --no-cache --virtual .phalcon-deps-build-deps \
         autoconf \
         g++ \
         make \
         bash \
         file \
         re2c \
    ; \
    \
    docker-php-ext-install -j$(nproc) gettext; \
    \
    apk del .phalcon-deps-build-deps

# Environment variables used in next build step
ENV PHALCON_VERSION 3.4.1
ENV PHALCON_CHECKSUM="5afcbb804b18768508bb53c7762f8daa6090a74c915de58afde1e36bfcc197c6"

# Download, verify checksum and compile, install Phalcon
RUN set -xe; \
    \
    apk add --no-cache --virtual .phalcon-build-deps \
         autoconf \
         g++ \
         make \
         bash \
         re2c \
         file \
    ; \
    \
    wget -O cphalcon-$PHALCON_VERSION.tar.gz "https://codeload.github.com/phalcon/cphalcon/tar.gz/v$PHALCON_VERSION"; \
    \
    echo "$PHALCON_CHECKSUM *cphalcon-$PHALCON_VERSION.tar.gz" | sha256sum -c -; \
    \
    tar -xzf cphalcon-$PHALCON_VERSION.tar.gz; \
    \
    cd cphalcon-$PHALCON_VERSION/build/php7/safe; \
    \
    export CC="gcc" \
              CFLAGS="$PHP_CFLAGS -fvisibility=hidden" \
              CPPFLAGS="$PHP_CPPFLAGS -DPHALCON_RELEASE" \
              LDFLAGS="$PHP_LDFLAGS"; \
    \
    phpize; \
    \
    ./configure --prefix=/usr --enable-phalcon; \
    \
    make && make install; \
    \
    cp ../../../tests/_ci/phalcon.ini $(php-config --configure-options | grep -o "with-config-file-scan-dir=\([^ ]*\)" | awk -F'=' '{print $2}'); \
    \
    cd ../../../../; \
    \
    rm -r cphalcon-$PHALCON_VERSION*; \
    \
    apk del .phalcon-build-deps

# Create cache directory, used by Phalcon by default usually
RUN set -xe; \
    \
    mkdir /var/www/html/cache; \
    \
    chown www-data:www-data /var/www/html/cache

# TODO: run php-fpm rootless (master too)
# TODO: configure php ini variables like previous Dockerfile
