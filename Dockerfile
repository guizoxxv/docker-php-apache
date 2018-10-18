FROM php:7.2.10-apache-stretch

RUN apt update

# Required for zip; php zip extension; png; node; vim; gd; gd; cron;
RUN apt install -y zip zlib1g-dev libpng-dev gnupg vim libfreetype6-dev libjpeg62-turbo-dev cron

# PHP extensions - pdo; mysql; zip (used to download packages with Composer); mbstring;
RUN docker-php-ext-install pdo_mysql zip mbstring

# GD (Image library)
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install -j$(nproc) gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install nodejs (comes with npm)
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt update && apt-get install -y nodejs

# Copy custom apache virtual host configuration into container
COPY vhost.conf /etc/apache2/sites-available/000-default.conf

# Set Apache Document Root - Replace APACHE_DOCUMENT_ROOT on vhost with APACHE_DOCUMENT_ROOT environment variable
RUN sed -ri -e 's!APACHE_DOCUMENT_ROOT!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf

# Copy start stript into container
COPY start.sh /usr/local/bin/start

# Set apache root permission
RUN chown -R www-data:www-data ${APACHE_DOCUMENT_ROOT}

# Activate Apache mod_rewrite
RUN a2enmod rewrite

# Set up the scheduler for Laravel
RUN echo '* * * * * cd /var/www/html && /usr/local/bin/php artisan schedule:run >> /dev/null 2>&1' | crontab -

# Set start script permission
RUN chmod u+x /usr/local/bin/start

# Cleanup
RUN apt clean
RUN apt autoclean

CMD ["/usr/local/bin/start"]
