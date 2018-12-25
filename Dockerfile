FROM php:7.2.13-fpm-alpine3.8
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
ENV PHALCON_VERSION 3.4.2
ENV PHALCON_CHECKSUM="217a4519c5e4e86cc9dacb30803a2dd7b77089e0fa8d31bb10c96163f18d6a9e"

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

# Create cache and .phalcon directory, used by Phalcon
RUN set -xe; \
    \
    mkdir /var/www/html/cache; \
    \
    chown www-data:www-data /var/www/html/cache; \
    \
    mkdir /var/www/html/.phalcon; \
    \
    chown www-data:www-data /var/www/html/.phalcon

# Configure secure defaults for PHP
RUN set -ex; \
    \
    { \
        echo '[PHP]'; \
        echo 'expose_php = Off'; \
        echo 'error_reporting = E_ALL'; \
        echo 'display_errors = Off'; \
        echo 'display_startup_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'ignore_repeated_errors = Off'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo 'open_basedir = /var/www/html/'; \
        echo 'allow_url_fopen = Off'; \
        echo 'allow_url_include = Off'; \
        echo 'enable_dl = Off'; \
        echo 'html_errors = Off'; \
        echo 'memory_limit = 8M'; \
        echo 'disable_functions = escapeshellarg, escapeshellcmd, exec, highlight_file, lchgrp, lchown, link, symlink, passthru, pclose, popen, proc_close, proc_get_status, proc_nice, proc_open, proc_terminate, shell_exec, show_source, system, gc_collect_cycles, gc_enable, gc_disable, gc_enabled, getmypid, getmyuid, getmygid, getrusage, getmyinode, get_current_user, phpinfo, phpversion, php_uname, putenv'; \
        echo 'max_input_time = 60'; \
        echo 'max_execution_time = 86400'; \
        echo; \
        echo '[Session]'; \
        echo 'session.use_strict_mode = On'; \
        echo 'session.use_cookies = On'; \
        echo 'session.use_only_cookies = On'; \
        echo 'session.sid_length = 52'; \
        echo 'session.sid_bits_per_character = 5'; \
    } | tee $PHP_INI_DIR/conf.d/99-secure-defaults.ini

# TODO: run php-fpm rootless (master too)
# TODO: configure php ini variables like previous Dockerfile
