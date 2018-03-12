FROM drupal:7-apache

#MAINTAINER: Ben Fairfield - benfa

#### Cosign Pre-requisites ###
WORKDIR /usr/lib/apache2/modules

ENV COSIGN_URL https://github.com/umich-iam/cosign/archive/cosign-3.4.0.tar.gz
ENV CPPFLAGS="-I/usr/kerberos/include"
ENV OPENSSL_VERSION 1.0.1t-1+deb8u7
ENV APACHE2=/usr/sbin/apache2

# install PHP and Apache2 here
RUN apt-get update \
	&& apt-get install -y wget gcc make openssl \
		libssl-dev=$OPENSSL_VERSION apache2-dev autoconf 

#<<<<<<< HEAD
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
#RUN composer global require drush/drush:7.*
RUN composer global require drush/drush
RUN export PATH="$HOME/.config/composer/vendor/bin:$PATH"
#RUN drush cc all
#=======
#RUN drush cc all --yes
#>>>>>>> 473e0070716089643a219bf2fe83533b061d6c5c

### Build Cosign ###
RUN wget "$COSIGN_URL" \
	&& mkdir -p src/cosign \
	&& tar -xvf cosign-3.4.0.tar.gz -C src/cosign --strip-components=1 \
	&& rm cosign-3.4.0.tar.gz \
	&& cd src/cosign \
	&& autoconf \
	&& ./configure --enable-apache2=/usr/bin/apxs \
	&& make \
	&& make install \
	&& cd ../../ \
	&& rm -r src/cosign \
	&& mkdir -p /var/cosign/filter \
	&& chmod 777 /var/cosign/filter

#WORKDIR /etc/apache2

### Remove pre-reqs ###
RUN apt-get remove -y make wget autoconf \
	&& apt-get autoremove -y

EXPOSE 443

COPY . /var/www/html/

### Start script incorporates config files and sends logs to stdout ###
COPY start.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/start.sh
CMD /usr/local/bin/start.sh
