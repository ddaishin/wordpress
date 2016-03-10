FROM php:5.6-apache

RUN a2enmod rewrite expires

# install the PHP extensions we need and vim git
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev vim git && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mysqli opcache mbstring

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# set xdebug
# see https://gist.github.com/chadrien/c90927ec2d160ffea9c4
RUN yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

# set extra PHP.ini settings
RUN { \
		echo 'date.timezone="Asia/Tokyo"'; \
		echo 'log_errors=On'; \
	} > /usr/local/etc/php/conf.d/php-extra.ini

# fix permission for osx
RUN usermod -u 1000 www-data \
	&& usermod -G staff www-data

VOLUME /var/www/html

ENV TZ JST-9
ENV WORDPRESS_VERSION latest-ja
ENV XDEBUG_CONFIG remote_host={{YOUR_IP_ADDRESS}}

# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://ja.wordpress.org/${WORDPRESS_VERSION}.tar.gz \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data /usr/src/wordpress

COPY docker-entrypoint.sh /entrypoint.sh

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
