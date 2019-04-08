FROM php:7.3-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libzip-dev \
	; \
	\
	NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j${NPROC} gd mysqli opcache zip mbstring mysql; \
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
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
		echo 'opcache.validate_timestamps=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
# https://codex.wordpress.org/Editing_wp-config.php#Configure_Error_Logging
RUN { \
		echo 'error_reporting = 4339'; \
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
		echo 'xdebug.remote_host = docker.for.mac.localhost'; \
	} >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Self signed SSL and SSMTP
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update; apt-get install -y --no-install-recommends ssmtp ssl-cert; make-ssl-cert generate-default-snakeoil && apt-get clean \
                                                                                         && rm -rf /var/lib/apt/lists/*
RUN { \
		echo 'sendmail_path = "/usr/sbin/ssmtp -t"'; \
	} >> /usr/local/etc/php/conf.d/docker-php-ext-smtp.ini

RUN a2enmod rewrite expires proxy proxy_http proxy_connect headers ssl && a2ensite default-ssl

VOLUME /var/www/html

ENV WORDPRESS_VERSION latest-ja

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://ja.wordpress.org/$WORDPRESS_VERSION.tar.gz"; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress; \
	sed -i "s/define('WP_DEBUG', false);/define('WP_DEBUG', true);\r\ndefine('DISABLE_WP_CRON', true);\r\ndefine('WP_SITEURL', 'http:\/\/' . \$_SERVER['HTTP_HOST'] );/g" /usr/src/wordpress/wp-config-sample.php;

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
