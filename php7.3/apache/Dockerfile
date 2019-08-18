FROM php:7.3-apache

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libzip-dev \
		libmemcached-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		mysqli \
		opcache \
		zip \
	; \
	pecl install imagick-3.4.4; \
	docker-php-ext-enable imagick; \
	pecl install memcached; \
	docker-php-ext-enable memcached; \
	pecl install apcu; \
	docker-php-ext-enable apcu; \
	pecl install xdebug; \
	docker-php-ext-enable xdebug; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=256'; \
		echo 'opcache.interned_strings_buffer=16'; \
		echo 'opcache.max_accelerated_files=10000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=0'; \
		echo 'opcache.enable_cli=1'; \
		echo 'opcache.validate_timestamps=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
# https://www.php.net/manual/en/errorfunc.constants.php
# https://github.com/docker-library/wordpress/issues/420#issuecomment-517839670
		echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

# set xdebug
RUN { \
		echo 'xdebug.remote_enable=1'; \
		echo 'xdebug.remote_host = host.docker.internal'; \
	} >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Self signed SSL
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update; apt-get install -y ssl-cert; make-ssl-cert generate-default-snakeoil && apt-get clean \
                                                                                         && rm -rf /var/lib/apt/lists/*
RUN a2enmod rewrite expires proxy proxy_http proxy_connect headers ssl && a2ensite default-ssl

VOLUME /var/www/html

ENV WORDPRESS_VERSION latest-ja

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://ja.wordpress.org/$WORDPRESS_VERSION.tar.gz"; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress; \
	sed -i "s/define('WP_DEBUG', false);/define('WP_DEBUG', true);\r\ndefine('WP_DEBUG_LOG', true);\r\ndefine('WP_DEBUG_DISPLAY', false);\r\ndefine('DISABLE_WP_CRON', true);\r\ndefine('WP_SITEURL', 'https:\/\/' . \$_SERVER['HTTP_HOST'] );/g" /usr/src/wordpress/wp-config-sample.php;

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
