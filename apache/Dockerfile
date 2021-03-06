FROM php:5.6-apache

RUN a2enmod rewrite expires

# install the PHP extensions
RUN apt-get update && apt-get upgrade -y && apt-get install -y libpng12-dev libjpeg-dev cron supervisor vim libmagickwand-dev libmagickcore-dev imagemagick libicu-dev \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install zip gd mysql mysqli opcache mbstring intl \
	&& apt-get autoremove \
	&& apt-get autoclean \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=0'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# set xdebug
# see https://gist.github.com/chadrien/c90927ec2d160ffea9c4
RUN yes | pecl install xdebug-2.5.5 \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

# ImageMaigck
RUN yes | pecl install imagick \
    && echo "extension=$(find /usr/local/lib/php/extensions/ -name imagick.so)" > /usr/local/etc/php/conf.d/imagick.ini

# set extra PHP.ini settings
RUN { \
		echo 'date.timezone="Asia/Tokyo"'; \
		echo 'log_errors=On'; \
		echo 'memory_limit=-1'; \
		echo 'max_execution_time=0'; \
		echo 'post_max_size=0'; \
		echo 'upload_max_filesize=2048G'; \
	} > /usr/local/etc/php/conf.d/php-extra.ini

# Add WP-CLI
# see https://github.com/conetix/docker-wordpress-wp-cli
RUN curl -o /bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /bin/wp-cli.phar
COPY wp-su.sh /bin/wp

# fix permission for osx
RUN usermod -u 1000 www-data \
	&& usermod -G staff www-data

VOLUME /var/www/html

ENV TZ JST-9
ENV XDEBUG_CONFIG remote_host=

COPY docker-entrypoint.sh /entrypoint.sh

# supervisor setup
ADD supervisord.conf /etc/supervisord.conf

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
