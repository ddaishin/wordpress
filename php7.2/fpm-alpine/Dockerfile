FROM php:7.2-fpm-alpine

# docker-entrypoint.sh dependencies
RUN apk add --no-cache \
# in theory, docker-entrypoint.sh is POSIX-compliant, but priority is a working, consistent image
		bash \
# BusyBox sed is not sufficient for some of our sed expressions
		sed

# install the PHP extensions we need
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
		libjpeg-turbo-dev \
		libpng-dev \
		icu-dev \
	; \
	\
	NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j${NPROC} gd mysqli opcache zip mbstring intl; \
	pecl install xdebug; \
	docker-php-ext-enable xdebug; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps $PHPIZE_DEPS

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# set xdebug
RUN { \
		echo 'xdebug.remote_enable=1'; \
		echo 'xdebug.remote_host = docker.for.mac.localhost'; \
	} >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

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
CMD ["php-fpm"]
