FROM debian:bookworm-slim

RUN apt-get update -y \
    && apt --no-install-recommends install apache2 php libapache2-mod-php \
                                    php-mysql php-zip php-mbstring php-common php-curl \
                                    php-gd php-db php-mail php-mail-mime \
                                    mariadb-client freeradius-utils rsyslog git vim nano -y \
    && apt-get clean

WORKDIR /var/www

RUN git clone https://github.com/lirantal/daloradius.git

RUN mkdir -p /var/log/apache2/daloradius/{operators,users} \
    && chown -R www-data:www-data /var/log/apache2/daloradius \
    && chown www-data:www-data /var/www/daloradius/contrib/scripts/dalo-crontab

WORKDIR /var/www/daloradius/app/common/includes

RUN cp daloradius.conf.php.sample daloradius.conf.php \
    && chown www-data:www-data daloradius.conf.php \
    && chmod 664 daloradius.conf.php

WORKDIR /var/www/daloradius/

RUN mkdir -p var/{log,backup} \
    && chown -R www-data:www-data var \
    && chmod -R 775 var

EXPOSE 80 8000

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
