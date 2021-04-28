FROM debian:buster-slim

EXPOSE 80
VOLUME /etc/letsencrypt
VOLUME /mlsploit/media

RUN apt-get update -y && apt-get install -y \
    apache2 libapache2-mod-wsgi-py3 \
    certbot python-certbot-apache

COPY mlsploit.conf /etc/apache2/conf-available/mlsploit.conf

RUN a2enconf mlsploit \
    && a2enmod ssl \
    && a2enmod wsgi \
    && a2enmod headers \
    && a2enmod proxy_http

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
